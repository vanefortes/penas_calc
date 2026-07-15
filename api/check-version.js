// api/check-version.js
//
// Endpoint da Vercel que informa a versão mais recente do app para o
// ANDROID (o iOS consulta direto a API pública da Apple — ver
// lib/services/update_service.dart, função _verificarIOS).
//
// A versão vem da ÚLTIMA RELEASE PUBLICADA no GitHub (não do branch
// master direto) — isso evita o app avisar sobre uma atualização antes
// dela estar de fato disponível para download na Google Play, já que a
// revisão da loja pode levar horas/dias após o seu `git push`.
//
// SEU NOVO FLUXO DE RELEASE NO ANDROID:
//   1. Suba o .aab na Google Play normalmente.
//   2. Espere a Play Store aprovar e publicar (ficar "live").
//   3. SÓ ENTÃO crie uma Release no GitHub (Releases → "Create a new
//      release"), com uma tag no formato "v1.0.1" (o "v" é opcional) e,
//      se quiser, uma descrição — ela vira as notas da atualização.
//   4. O endpoint detecta essa release automaticamente na próxima
//      consulta; nada para editar ou fazer deploy aqui.
//
// A API do GitHub para "última release" (/releases/latest) já ignora
// releases marcadas como rascunho ou pré-lançamento — então dá pra usar
// pré-lançamentos como uma espécie de "release interna" sem que os
// usuários finais recebam o aviso de atualização por causa dela.
//
// Uso: GET /api/check-version?platform=android
//
// O que ainda é manual (edite abaixo quando quiser):
//   MIN_VERSION_ANDROID — se preenchido, força atualização de quem
//                         estiver com versão abaixo dela (deixe vazio
//                         para nunca forçar)
//
// Variável de ambiente necessária (configure em Vercel → Settings →
// Environment Variables):
//   GITHUB_TOKEN — Personal Access Token (classic ou fine-grained) com
//                  permissão de LEITURA de conteúdo no repositório
//                  vanefortes/penas_calc. Gere em:
//                  github.com/settings/tokens

const GITHUB_OWNER = 'vanefortes';
const GITHUB_REPO = 'penas_calc';

// ───── Edite este valor quando quiser, sem mexer no resto ─────
const MIN_VERSION_ANDROID = ''; // ex: '1.0.1' para forçar atualização

const URL_PLAY_STORE =
  'https://play.google.com/store/apps/details?id=com.vforttes.penas_calc';
// ────────────────────────────────────────────────────────────

// Notas maiores que isso são cortadas, para não estourar a tela de
// atualização com uma descrição de release muito longa.
const LIMITE_NOTAS = 300;

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
    const release = await buscarUltimaRelease(token);

    if (!release) {
      res.status(200).json(VAZIO);
      return;
    }

    res.status(200).json({
      latestVersion: release.versao,
      minVersion: MIN_VERSION_ANDROID,
      notes: release.notas,
      url: URL_PLAY_STORE,
    });
  } catch (erro) {
    console.error('Erro ao buscar release no GitHub:', erro);
    res.status(200).json(VAZIO);
  }
}

async function buscarUltimaRelease(token) {
  const apiUrl =
    `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest`;

  const resposta = await fetch(apiUrl, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'User-Agent': 'penas-calc-check-version',
    },
  });

  // 404 = nenhuma release publicada ainda (repositório novo, ou só drafts
  // / pré-lançamentos até agora) — não é um erro, apenas "sem novidade".
  if (resposta.status === 404) return null;

  if (!resposta.ok) {
    const texto = await resposta.text();
    console.error('Erro ao buscar release:', resposta.status, texto);
    return null;
  }

  const dados = await resposta.json();
  const tag = (dados.tag_name || '').trim();

  // Aceita tags como "v1.0.1", "1.0.1", "release-1.0.1", etc. — extrai
  // só a parte numérica no formato x.y.z.
  const match = tag.match(/([0-9]+\.[0-9]+\.[0-9]+)/);
  if (!match) return null;

  const notasBrutas = (dados.body || '').trim();
  const notas =
    notasBrutas.length > LIMITE_NOTAS
      ? `${notasBrutas.slice(0, LIMITE_NOTAS)}…`
      : notasBrutas;

  return { versao: match[1], notas };
}
