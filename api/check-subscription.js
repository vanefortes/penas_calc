// api/check-subscription.js
//
// Endpoint da Vercel que verifica se um usuário tem assinatura ativa
// no RevenueCat, consultando a API REST com a chave SECRETA (nunca
// exposta no front-end).
//
// Uso: GET /api/check-subscription?appUserId=SEU_ID_DE_USUARIO
//
// Variável de ambiente necessária (já configurada na Vercel):
//   REVENUECAT_SECRET_API_KEY

// Precisa ser IDÊNTICO ao nome do entitlement cadastrado no RevenueCat
// (o mesmo usado em kEntitlementPremium no app Flutter).
const ENTITLEMENT_ID = 'Calculadora Penal Pro';

export default async function handler(req, res) {
  // CORS básico — ajuste o domínio conforme onde o Flutter Web estiver hospedado.
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

  const { appUserId } = req.query;

  if (!appUserId || typeof appUserId !== 'string') {
    res.status(400).json({ error: 'Parâmetro "appUserId" é obrigatório.' });
    return;
  }

  const secretKey = process.env.REVENUECAT_SECRET_API_KEY;
  if (!secretKey) {
    console.error('REVENUECAT_SECRET_API_KEY não configurada nas variáveis de ambiente.');
    res.status(500).json({ error: 'Configuração do servidor incompleta.' });
    return;
  }

  try {
    const rcResponse = await fetch(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
      {
        headers: {
          Authorization: `Bearer ${secretKey}`,
          'Content-Type': 'application/json',
        },
      },
    );

    // Usuário ainda não existe no RevenueCat (nunca comprou/nunca foi identificado).
    if (rcResponse.status === 404) {
      res.status(200).json({ premium: false });
      return;
    }

    if (!rcResponse.ok) {
      const texto = await rcResponse.text();
      console.error('Erro na API do RevenueCat:', rcResponse.status, texto);
      res.status(502).json({ error: 'Falha ao consultar o RevenueCat.' });
      return;
    }

    const data = await rcResponse.json();
    const entitlement = data?.subscriber?.entitlements?.[ENTITLEMENT_ID];

    const premium =
      !!entitlement &&
      (!entitlement.expires_date || new Date(entitlement.expires_date) > new Date());

    res.status(200).json({
      premium,
      expiresDate: entitlement?.expires_date ?? null,
    });
  } catch (erro) {
    console.error('Erro inesperado ao checar assinatura:', erro);
    res.status(500).json({ error: 'Erro interno ao verificar assinatura.' });
  }
}
