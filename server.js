const express = require('express');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { spawnSync } = require('child_process');
const dotenv = require('dotenv');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const DWG_UPLOAD_ROOT = path.join(__dirname, 'DWG_PIPELINE', '05_uploads_site');
const DWG_UPLOAD_MANIFEST = path.join(__dirname, 'OUTPUT', 'dwg', 'dwg_site_uploads_latest.json');
const DWG_SAFE_ROOT = process.env.DWG_SAFE_ROOT || 'C:\\DWG_WORK\\site_upload_jobs';
const ODA_EXE = process.env.ODA_EXE || 'C:\\Program Files\\ODA\\ODAFileConverter 27.1.0\\ODAFileConverter.exe';
const OGR2OGR_EXE = process.env.OGR2OGR_EXE || 'C:\\Program Files\\QGIS 3.44.9\\bin\\ogr2ogr.exe';
const OGRINFO_EXE = process.env.OGRINFO_EXE || 'C:\\Program Files\\QGIS 3.44.9\\bin\\ogrinfo.exe';
const DWG_SOURCE_CRS = process.env.DWG_SOURCE_CRS || 'EPSG:31983';
const INLINE_GEOJSON_MAX_BYTES = 15 * 1024 * 1024;
const INLINE_GEOJSON_MAX_FEATURES = 12000;
const ROOT_STATIC_FILES = new Set([
  'index.html',
  'mapa-rede-optica.html',
  'dashboard.html',
  'ia-assistente.html',
  'auditoria-revisao.html',
  'favicon.svg',
  'manifest.json',
  'sw.js',
  'service-worker.js',
  'science_sites_mg.json',
  'sync_robusto_retry.js',
  'tratamento_erros_profissional.js',
  'otimizacao_ux_mobile.js'
]);

// Configuração Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;
const supabaseAppToken = process.env.SUPABASE_APP_TOKEN;
const hasSupabaseConfig = Boolean(supabaseUrl && supabaseKey);

if (!hasSupabaseConfig) {
  console.warn('AVISO: SUPABASE_URL ou SUPABASE_ANON_KEY não configurados; rotas dependentes de banco responderão 503.');
}

const supabase = hasSupabaseConfig ? createClient(supabaseUrl, supabaseKey) : null;

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function sanitizeUploadFileName(fileName) {
  return String(fileName || '')
    .replace(/[<>:"/\\|?*\u0000-\u001F]/g, '-')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 180);
}

function readUploadManifest() {
  try {
    const raw = fs.readFileSync(DWG_UPLOAD_MANIFEST, 'utf8');
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function writeUploadManifest(entries) {
  ensureDir(path.dirname(DWG_UPLOAD_MANIFEST));
  fs.writeFileSync(DWG_UPLOAD_MANIFEST, JSON.stringify(entries, null, 2), 'utf8');
}

function updateUploadEntry(entryId, updater) {
  const uploads = readUploadManifest();
  const index = uploads.findIndex((item) => item.id === entryId);
  if (index < 0) return null;
  uploads[index] = updater({ ...uploads[index] });
  writeUploadManifest(uploads);
  return uploads[index];
}

function findUploadEntry(entryId) {
  return readUploadManifest().find((item) => item.id === entryId) || null;
}

function slugifyStem(text) {
  return sanitizeUploadFileName(path.parse(String(text || 'arquivo')).name)
    .toLowerCase()
    .replace(/[^a-z0-9-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '') || 'dwg-upload';
}

function execBinary(filePath, args, options = {}) {
  const result = spawnSync(filePath, args, {
    cwd: options.cwd || path.dirname(filePath),
    encoding: 'utf8',
    windowsHide: true
  });
  if (result.error) {
    throw result.error;
  }
  const stdout = result.stdout || '';
  const stderr = result.stderr || '';
  if (result.status !== 0) {
    throw new Error(`${path.basename(filePath)} falhou com código ${result.status}: ${stderr || stdout || 'sem detalhes'}`);
  }
  return { stdout, stderr };
}

function getGeoJsonFeatureCount(geoJsonPath) {
  if (!fs.existsSync(OGRINFO_EXE)) return 0;
  const result = execBinary(OGRINFO_EXE, ['-ro', '-al', '-so', geoJsonPath]);
  const match = String(result.stdout || '').match(/Feature Count:\s*(\d+)/i);
  return match ? Number(match[1]) : 0;
}

function loadInlineGeoJson(geoJsonPath) {
  const stats = fs.statSync(geoJsonPath);
  if (stats.size > INLINE_GEOJSON_MAX_BYTES) {
    return null;
  }
  const parsed = JSON.parse(fs.readFileSync(geoJsonPath, 'utf8'));
  const features = Array.isArray(parsed?.features) ? parsed.features : [];
  if (features.length > INLINE_GEOJSON_MAX_FEATURES) {
    return null;
  }
  return parsed;
}

function annotateFeatureCollection(featureCollection, meta = {}) {
  const features = Array.isArray(featureCollection?.features) ? featureCollection.features : [];
  return {
    type: 'FeatureCollection',
    features: features.map((feature) => ({
      ...feature,
      properties: {
        ...(feature.properties || {}),
        import_source: meta.file_name || feature?.properties?.import_source || 'dwg-upload',
        import_format: 'dwg',
        geometry_type: feature?.geometry?.type || feature?.properties?.geometry_type || '',
        imported_at: meta.imported_at || new Date().toISOString()
      }
    }))
  };
}

function ensureSupabaseReady(res) {
  if (supabase) {
    return true;
  }
  res.status(503).json({
    ok: false,
    error: 'Supabase não configurado neste ambiente.',
    code: 'supabase_unconfigured'
  });
  return false;
}

function convertUploadedDwg(entry) {
  if (!fs.existsSync(ODA_EXE)) {
    return { ok: false, status: 'tools_missing', error: `ODA File Converter não encontrado em ${ODA_EXE}` };
  }
  if (!fs.existsSync(OGR2OGR_EXE)) {
    return { ok: false, status: 'tools_missing', error: `ogr2ogr não encontrado em ${OGR2OGR_EXE}` };
  }

  const jobId = `site_${new Date().toISOString().replace(/[-:TZ.]/g, '').slice(0, 14)}_${entry.id.slice(0, 8)}`;
  const safeRoot = path.join(DWG_SAFE_ROOT, jobId);
  const safeInputDir = path.join(safeRoot, 'in');
  const safeOutputDir = path.join(safeRoot, 'out_dxf');
  const publishDxfDir = path.join(__dirname, 'DWG_PIPELINE', '30_convertidos_dxf', jobId);
  const publishGeoJsonDir = path.join(__dirname, 'DWG_PIPELINE', '40_convertidos_geojson', jobId);
  const baseName = slugifyStem(entry.file_name);
  const safeInputFile = path.join(safeInputDir, 'dwg_001.dwg');
  const tempDxfFile = path.join(safeOutputDir, 'dwg_001.dxf');
  const publishedDxfFile = path.join(publishDxfDir, `${baseName}.dxf`);
  const publishedGeoJsonFile = path.join(publishGeoJsonDir, `${baseName}.geojson`);
  const importedAt = new Date().toISOString();

  ensureDir(safeInputDir);
  ensureDir(safeOutputDir);
  ensureDir(publishDxfDir);
  ensureDir(publishGeoJsonDir);
  fs.copyFileSync(entry.stored_path, safeInputFile);

  try {
    execBinary(ODA_EXE, [safeInputDir, safeOutputDir, 'ACAD2018', 'DXF', '0', '0']);
    if (!fs.existsSync(tempDxfFile)) {
      throw new Error('ODA concluiu sem produzir DXF temporário.');
    }
    fs.copyFileSync(tempDxfFile, publishedDxfFile);
    execBinary(OGR2OGR_EXE, ['-f', 'GeoJSON', '-s_srs', DWG_SOURCE_CRS, '-t_srs', 'EPSG:4326', publishedGeoJsonFile, publishedDxfFile, 'entities']);
    if (!fs.existsSync(publishedGeoJsonFile)) {
      throw new Error('Conversão para GeoJSON não gerou arquivo de saída.');
    }

    const dxfSize = fs.statSync(publishedDxfFile).size;
    const geojsonSize = fs.statSync(publishedGeoJsonFile).size;
    const featureCount = getGeoJsonFeatureCount(publishedGeoJsonFile);
    const inlineGeoJson = loadInlineGeoJson(publishedGeoJsonFile);

    return {
      ok: true,
      status: 'converted',
      imported_at: importedAt,
      source_crs_assumed: DWG_SOURCE_CRS,
      dxf_path: publishedDxfFile,
      geojson_path: publishedGeoJsonFile,
      dxf_size_bytes: dxfSize,
      geojson_size_bytes: geojsonSize,
      feature_count: featureCount,
      geojson_url: `/api/dwg/uploads/${entry.id}/geojson`,
      dxf_url: `/api/dwg/uploads/${entry.id}/dxf`,
      feature_collection: inlineGeoJson ? annotateFeatureCollection(inlineGeoJson, { file_name: entry.file_name, imported_at: importedAt }) : null
    };
  } catch (error) {
    return {
      ok: false,
      status: 'conversion_failed',
      error: error.message,
      source_crs_assumed: DWG_SOURCE_CRS
    };
  }
}

// Middlewares
app.use(helmet({
  contentSecurityPolicy: false, // Desabilitado temporariamente para facilitar transição com Leaflet/CDNs
}));
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

app.use('/js', express.static(path.join(__dirname, 'js')));
app.use('/styles', express.static(path.join(__dirname, 'styles')));
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});
app.get('/:fileName', (req, res, next) => {
  const { fileName } = req.params;
  if (!ROOT_STATIC_FILES.has(fileName)) {
    return next();
  }
  const filePath = path.join(__dirname, fileName);
  if (!fs.existsSync(filePath)) {
    return next();
  }
  return res.sendFile(filePath);
});

// API: Health Check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API: Login Seguro
app.post('/api/auth/login', async (req, res) => {
  if (!ensureSupabaseReady(res)) {
    return;
  }

  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'E-mail e senha são obrigatórios.' });
  }

  try {
    // Chama a RPC segura fn_auth_login_usuario no Supabase
    const { data, error } = await supabase.rpc('fn_auth_login_usuario', {
      p_email: email,
      p_senha: password
    });

    if (error) {
      console.error('Erro de autenticação (Supabase):', error);
      return res.status(401).json({ error: 'Falha na autenticação.', details: error.message });
    }

    if (!data || data.length === 0) {
      return res.status(401).json({ error: 'Credenciais inválidas ou usuário inativo.' });
    }

    const user = Array.isArray(data) ? data[0] : data;

    // TODO: Gerar um JWT próprio ou retornar os dados do usuário para o front
    // Para simplificar a transição, retornaremos o usuário (que não contém o hash da senha)
    res.json({
      ok: true,
      user: {
        id: user.id,
        nome: user.nome,
        email: user.email,
        perfil: user.perfil
      },
      token: supabaseKey, // Enviamos a Anon Key para o front continuar usando o Supabase Client se necessário
      app_token: supabaseAppToken
    });

  } catch (err) {
    console.error('Erro inesperado no login:', err);
    res.status(500).json({ error: 'Erro interno no servidor de autenticação.' });
  }
});

// API: Proxy para logs estruturados no banco
app.post('/api/logs', async (req, res) => {
  if (!ensureSupabaseReady(res)) {
    return;
  }

  const { event, details, user_email } = req.body;

  try {
    const { error } = await supabase.from('auditoria_eventos').insert({
      tabela_nome: 'ui_event',
      acao: event,
      usuario: user_email || 'anonymous',
      detalhes: details,
      origem_acao: 'frontend',
      request_origin: req.ip
    });

    if (error) throw error;
    res.status(201).json({ ok: true });
  } catch (err) {
    console.error('Falha ao registrar log:', err);
    res.status(500).json({ error: 'Falha ao registrar log.' });
  }
});

app.get('/api/dwg/health', (req, res) => {
  res.json({
    ok: true,
    upload_root: DWG_UPLOAD_ROOT,
    manifest_path: DWG_UPLOAD_MANIFEST,
    tools: {
      oda: fs.existsSync(ODA_EXE),
      ogr2ogr: fs.existsSync(OGR2OGR_EXE),
      ogrinfo: fs.existsSync(OGRINFO_EXE)
    }
  });
});

app.get('/api/dwg/uploads', (req, res) => {
  res.json({
    ok: true,
    uploads: readUploadManifest().slice(0, 20)
  });
});

app.get('/api/dwg/uploads/:id/geojson', (req, res) => {
  const entry = findUploadEntry(req.params.id);
  const geojsonPath = entry?.conversion?.geojson_path;
  if (!entry || !geojsonPath || !fs.existsSync(geojsonPath)) {
    return res.status(404).json({ ok: false, error: 'GeoJSON convertido não encontrado.' });
  }
  res.sendFile(geojsonPath);
});

app.get('/api/dwg/uploads/:id/dxf', (req, res) => {
  const entry = findUploadEntry(req.params.id);
  const dxfPath = entry?.conversion?.dxf_path;
  if (!entry || !dxfPath || !fs.existsSync(dxfPath)) {
    return res.status(404).json({ ok: false, error: 'DXF convertido não encontrado.' });
  }
  res.sendFile(dxfPath);
});

app.post('/api/dwg/upload', express.raw({ type: 'application/octet-stream', limit: '250mb' }), (req, res) => {
  const encodedName = req.get('x-file-name') || '';
  let originalName = '';

  try {
    originalName = decodeURIComponent(encodedName);
  } catch {
    originalName = encodedName;
  }

  if (!originalName || !/\.dwg$/i.test(originalName)) {
    return res.status(400).json({ ok: false, error: 'Envie um arquivo .dwg válido.' });
  }

  if (!Buffer.isBuffer(req.body) || req.body.length === 0) {
    return res.status(400).json({ ok: false, error: 'Corpo binário vazio.' });
  }

  const safeName = sanitizeUploadFileName(path.basename(originalName));
  const stamp = new Date().toISOString().replace(/[-:TZ.]/g, '').slice(0, 14);
  const storedName = `${stamp}__${safeName}`;
  const storedPath = path.join(DWG_UPLOAD_ROOT, storedName);

  ensureDir(DWG_UPLOAD_ROOT);
  fs.writeFileSync(storedPath, req.body);

  const sha256 = crypto.createHash('sha256').update(req.body).digest('hex');
  const entry = {
    id: crypto.randomUUID(),
    file_name: originalName,
    stored_name: storedName,
    stored_path: storedPath,
    size_bytes: req.body.length,
    sha256,
    uploaded_at: new Date().toISOString(),
    source: 'site_upload',
    processing_status: 'uploaded'
  };

  const uploads = readUploadManifest();
  uploads.unshift(entry);
  writeUploadManifest(uploads.slice(0, 200));

  const conversion = convertUploadedDwg(entry);
  const manifestSafeConversion = {
    ...conversion,
    feature_collection: null,
    inline_feature_collection: !!conversion.feature_collection
  };
  const updatedEntry = updateUploadEntry(entry.id, (current) => ({
    ...current,
    processing_status: conversion.ok ? 'converted' : 'stored_only',
    conversion: manifestSafeConversion
  })) || { ...entry, conversion: manifestSafeConversion };

  res.status(201).json({
    ok: true,
    entry: updatedEntry,
    conversion,
    feature_collection: conversion.feature_collection || null
  });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`
  🚀 FIBRA CADASTRO - Servidor Corporativo Iniciado
  ------------------------------------------------
  URL: http://localhost:${PORT}
  Database: ${supabaseUrl || 'não configurado'}
  Status: Ativo
  ------------------------------------------------
  `);
});
