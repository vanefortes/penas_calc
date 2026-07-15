// api/check-version.js
//
// Endpoint da Vercel que informa a versão mais recente do app para o
// ANDROID (o iOS consulta direto a API pública da Apple — ver
// lib/services/update_service.dart, função _verificarIOS).
//
// A versão é lida automaticamente do pubspec.yaml no GitHub (repo
// privado), então o único passo de release no Android é: dar bump na
// versão em pubspec.yaml e fazer push. Não precisa editar este arquivo
// para isso.
//
// O que ainda é manual (edite abaixo quando quiser):
//   NOTES_ANDROID       — texto exibido na seção "O que há de novo"
//   MIN_VERSION_ANDROID — se preenchido, força atualização de quem
//                         estiver com versão abaixo dela (deixe vazio
//                         para nunca forçar)
//
// Uso: GET /api/check-version?platform=android
//
// Variável de ambiente necessária (configure em Vercel → Settings →
// Environment Variables):
//   GITHUB_TOKEN — Personal Access Token (classic ou fine-grained) com
//                  permissão de LEITURA de conteúdo no repositório
//                  vanefortes/penas_calc. Gere em:
//                  github.com/settings/tokens

const GITHUB_OWNER = 'vanefortes';
const GITHUB_REPO = 'penas_calc';
const GITHUB_BRANCH = 'master';

// ───── Edite estes 2 valores quando quiser, sem mexer no resto ─────
const NOTES_ANDROID = '';
const MIN_VERSION_ANDROID = ''; // ex: '1.0.1' para forçar atualização

const URL_PLAY_STORE =
  'https://play.google.com/store/apps/details?id=com.vforttes.penas_calc';
// ─────────────────────────────────────────────────────────────────

const VAZIO = { latestVersion: '', minVersion: '', notes: '', url: '' };

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Método não permitido. Use GET.' });
    return;
  }

  const { platform } = req.query;

  // Só o Android usa este endpoint; qualquer outra plataforma recebe vazio.
  if (platform !== 'android') {
    res.status(200).json(VAZIO);
    return;
  }

  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    console.error('GITHUB_TOKEN não configurada nas variáveis de ambiente.');
    res.status(200).json(VAZIO);
    return;
  }

  try {
    const versao = await buscarVersaoNoPubspec(token);

    if (!versao) {
      res.status(200).json(VAZIO);
      return;
    }

    res.status(200).json({
      latestVersion: versao,
      minVersion: MIN_VERSION_ANDROID,
      notes: NOTES_ANDROID,
      url: URL_PLAY_STORE,
    });
  } catch (erro) {
    console.error('Erro ao buscar versão no GitHub:', erro);
    res.status(200).json(VAZIO);
  }
}

async function buscarVersaoNoPubspec(token) {
  const apiUrl =
    `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/pubspec.yaml?ref=${GITHUB_BRANCH}`;

  const resposta = await fetch(apiUrl, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github.raw+json',
      'User-Agent': 'penas-calc-check-version',
    },
  });

  if (!resposta.ok) {
    const texto = await resposta.text();
    console.error('Erro ao buscar pubspec.yaml:', resposta.status, texto);
    return null;
  }

  const conteudo = await resposta.text();

  // Procura a linha "version: 1.0.0+6" e extrai só a parte semântica
  // (antes do "+"), que é o número exibido nas lojas.
  const match = conteudo.match(/^version:\s*([0-9]+\.[0-9]+\.[0-9]+)/m);
  return match ? match[1] : null;
}
