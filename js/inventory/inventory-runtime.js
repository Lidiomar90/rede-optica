(() => {
  const foundation = window.AppFoundation || null;

  function log(level, event, context = {}) {
    if (foundation && typeof foundation.log === 'function') {
      foundation.log(level, event, context);
      return;
    }
    const fn = level === 'error' ? console.error : level === 'warn' ? console.warn : console.log;
    fn(`[INVENTORY:${level}] ${event}`, context);
  }

  function arr(value) {
    return Array.isArray(value) ? value : [];
  }

  function getStore() {
    try {
      return typeof window.getInvStore === 'function' ? window.getInvStore() : {};
    } catch {
      return {};
    }
  }

  function escapeHtml(value) {
    if (typeof window.esc === 'function') return window.esc(String(value ?? ''));
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function formatKm(value) {
    if (typeof window.km === 'function') return window.km(value);
    const n = Number(value || 0);
    if (!Number.isFinite(n) || n <= 0) return '—';
    return `${(n / 1000).toFixed(2)} km`;
  }

  function snapshot() {
    const store = getStore();
    return {
      ts: new Date().toISOString(),
      oficiais: {
        sites: arr(window.allS).length,
        cabos: arr(window.allC).length,
        caixas: arr(window.officialCaixas).length,
        dgos: arr(window.officialDgos).length,
        segmentos: arr(window.officialSegmentos).length,
        rupturas: arr(window.officialRupturas).length
      },
      rascunhos: {
        caixas: arr(store.caixas).length,
        dgos: arr(store.dgos).length,
        segmentos: arr(store.segmentos).length,
        rupturas: arr(store.rupturas).length
      }
    };
  }

  function findCable(cableId) {
    return arr(window.allC).find(item => String(item.id) === String(cableId)) || null;
  }

  function findCaixa(caixaId) {
    const store = getStore();
    return arr(window.officialCaixas).find(item => String(item.id) === String(caixaId))
      || arr(store.caixas).find(item => String(item.id) === String(caixaId))
      || null;
  }

  function findDgo(dgoId) {
    const store = getStore();
    return arr(window.officialDgos).find(item => String(item.id) === String(dgoId))
      || arr(store.dgos).find(item => String(item.id) === String(dgoId))
      || null;
  }

  function uniqueById(items) {
    const map = new Map();
    arr(items).forEach(item => {
      const key = String(item?.id || item?.codigo || item?.nome || '');
      if (!key) return;
      if (!map.has(key)) map.set(key, item);
    });
    return [...map.values()];
  }

  function relatedSegmentsForCable(cable) {
    const cableId = String(cable?.id || '');
    const refs = new Set(
      [String(cable?.codigo || ''), String(cable?.nome || ''), cableId]
        .filter(Boolean)
        .map(x => x.toLowerCase())
    );
    const store = getStore();
    return arr(window.officialSegmentos)
      .concat(arr(store.segmentos))
      .filter(seg => {
        const localRefs = [seg.cabo_id, seg.cabo, seg.codigo, seg.nome]
          .filter(Boolean)
          .map(x => String(x).toLowerCase());
        return localRefs.some(ref => refs.has(ref));
      });
  }

  function buildCableDiagramModel(cableId) {
    const cable = findCable(cableId);
    if (!cable) return null;

    const segments = relatedSegmentsForCable(cable);
    const caixaIds = new Set();
    const dgoIds = new Set();

    segments.forEach(seg => {
      [seg.ponta_a_caixa_id, seg.ponta_b_caixa_id, seg.origem_caixa_id, seg.destino_caixa_id].forEach(id => {
        if (id) caixaIds.add(String(id));
      });
      [seg.ponta_a_dgo_id, seg.ponta_b_dgo_id, seg.dgo_a_id, seg.dgo_b_id].forEach(id => {
        if (id) dgoIds.add(String(id));
      });
    });

    [cable.origem_caixa_id, cable.destino_caixa_id].forEach(id => {
      if (id) caixaIds.add(String(id));
    });
    [cable.dgo_a_id, cable.dgo_b_id].forEach(id => {
      if (id) dgoIds.add(String(id));
    });

    const boxes = uniqueById(
      [...caixaIds].map(findCaixa).filter(Boolean)
        .concat(arr(window.officialCaixas).filter(cx => String(cx.cabo_id || '') === String(cable.id)))
    );
    const dgos = uniqueById([...dgoIds].map(findDgo).filter(Boolean));
    const incidents = arr(window.allInc).filter(item =>
      String(item.cabo_id || '') === String(cable.id) ||
      String(item.enlace_id || '') === String(cable.id) ||
      (item.titulo && String(item.titulo).toLowerCase().includes(String(cable.codigo || cable.nome || '').toLowerCase()))
    );

    return {
      kind: 'cabo',
      entity: cable,
      segments: uniqueById(segments),
      boxes,
      dgos,
      incidents
    };
  }

  function buildCaixaDiagramModel(caixaId) {
    const caixa = findCaixa(caixaId);
    if (!caixa) return null;

    const segments = arr(window.officialSegmentos).concat(arr(getStore().segmentos)).filter(seg =>
      [seg.ponta_a_caixa_id, seg.ponta_b_caixa_id, seg.origem_caixa_id, seg.destino_caixa_id].some(id => String(id || '') === String(caixa.id))
    );

    const cables = uniqueById(
      segments.map(seg => findCable(seg.cabo_id)).filter(Boolean)
        .concat(arr(window.allC).filter(c => String(c.id || '') === String(caixa.cabo_id || '')))
    );
    const dgos = uniqueById(
      segments
        .flatMap(seg => [seg.ponta_a_dgo_id, seg.ponta_b_dgo_id, seg.dgo_a_id, seg.dgo_b_id])
        .filter(Boolean)
        .map(findDgo)
        .filter(Boolean)
        .concat(caixa.dgo_id ? [findDgo(caixa.dgo_id)] : [])
    );

    return {
      kind: 'caixa',
      entity: caixa,
      segments: uniqueById(segments),
      cables,
      dgos
    };
  }

  function buildDgoDiagramModel(dgoId) {
    const dgo = findDgo(dgoId);
    if (!dgo) return null;

    const segments = arr(window.officialSegmentos).concat(arr(getStore().segmentos)).filter(seg =>
      [seg.ponta_a_dgo_id, seg.ponta_b_dgo_id, seg.dgo_a_id, seg.dgo_b_id].some(id => String(id || '') === String(dgo.id))
    );
    const cables = uniqueById(segments.map(seg => findCable(seg.cabo_id)).filter(Boolean));
    const boxes = uniqueById(
      segments
        .flatMap(seg => [seg.ponta_a_caixa_id, seg.ponta_b_caixa_id, seg.origem_caixa_id, seg.destino_caixa_id])
        .filter(Boolean)
        .map(findCaixa)
        .filter(Boolean)
    );

    return {
      kind: 'dgo',
      entity: dgo,
      segments: uniqueById(segments),
      cables,
      boxes
    };
  }

  function renderRelationList(title, items, formatter) {
    if (!items.length) return '';
    return `
      <div class="diag-card">
        <div class="diag-title">${escapeHtml(title)}</div>
        <div class="diag-list">${items.map(formatter).join('')}</div>
      </div>
    `;
  }

  function renderBadges(model) {
    const entries = [
      [model.kind.toUpperCase()],
      [`${(model.segments || []).length} segmento(s)`],
      model.boxes ? [`${model.boxes.length} caixa(s)`] : null,
      model.dgos ? [`${model.dgos.length} DGO(s)`] : null,
      model.cables ? [`${model.cables.length} cabo(s)`] : null,
      model.incidents ? [`${model.incidents.length} incidente(s)`] : null
    ].filter(Boolean);
    if (typeof window.buildOperationalBadges === 'function') {
      return window.buildOperationalBadges(entries);
    }
    return entries.map(([label]) => `<span style="display:inline-flex;padding:4px 8px;border-radius:999px;background:rgba(77,166,255,.12);border:1px solid rgba(77,166,255,.28);font-size:10px;color:#dbe7ff">${escapeHtml(label)}</span>`).join('');
  }

  function openOperationalDiagram(kind, id) {
    let model = null;
    if (kind === 'cabo') model = buildCableDiagramModel(id);
    if (kind === 'caixa') model = buildCaixaDiagramModel(id);
    if (kind === 'dgo') model = buildDgoDiagramModel(id);
    if (!model) {
      foundation?.notify?.('Diagrama operacional indisponível para este ativo.', 'warning');
      return null;
    }

    const entity = model.entity;
    const rows = [];
    if (kind === 'cabo') {
      rows.push(['Tipo', entity.tipo || '—']);
      rows.push(['Camada', entity.camada || '—']);
      rows.push(['Comprimento', formatKm(entity.comprimento_m || entity.comprimento)]);
      rows.push(['Status', entity.status || '—']);
    } else if (kind === 'caixa') {
      rows.push(['Nome', entity.nome || '—']);
      rows.push(['Tipo', entity.tipo || entity.tipo_instalacao || '—']);
      rows.push(['Status', entity.status || '—']);
    } else {
      rows.push(['Código', entity.codigo || '—']);
      rows.push(['Site', entity.site_codigo || entity.site_nome || '—']);
      rows.push(['Rack/Fila', [entity.rack, entity.fila, entity.bastidor].filter(Boolean).join(' / ') || '—']);
    }

    if (typeof window.showPan === 'function') {
      window.showPan(
        `🧬 Diagrama ${kind === 'cabo' ? 'do cabo' : kind === 'caixa' ? 'da caixa' : 'do DGO'} ${entity.codigo || entity.nome || ''}`.trim(),
        rows,
        [{ l: '↩ Voltar', c: 'b', fn: 'closePan()' }]
      );

      const panelBody = document.getElementById('pb');
      if (panelBody) {
        panelBody.innerHTML += `
          <div style="margin-top:12px">
            <div style="font-size:10px;color:var(--cy);font-weight:800;text-transform:uppercase;letter-spacing:.12em;margin-bottom:6px">Visão operacional</div>
            <div style="display:flex;gap:6px;flex-wrap:wrap">${renderBadges(model)}</div>
          </div>
          ${renderRelationList('Segmentos', model.segments || [], seg => `
            <div class="diag-item">
              <div class="diag-item-title">${escapeHtml(seg.cabo || seg.codigo || 'Segmento')}</div>
              <div class="diag-item-meta">${escapeHtml(seg.ponto_a || '—')} → ${escapeHtml(seg.ponto_b || '—')} • ${escapeHtml(seg.tipo_lancamento || '—')} • ${escapeHtml(formatKm(seg.metragem_m))}</div>
            </div>`)}
          ${renderRelationList('Caixas / pontos de emenda', model.boxes || [], cx => `
            <div class="diag-item">
              <div class="diag-item-title">${escapeHtml(cx.codigo || cx.nome || 'Caixa')}</div>
              <div class="diag-item-meta">${escapeHtml(cx.nome || '—')} • ${escapeHtml(cx.status || '—')} • ${escapeHtml(cx.tipo || cx.tipo_instalacao || '—')}</div>
            </div>`)}
          ${renderRelationList('DGOs / terminações', model.dgos || [], dg => `
            <div class="diag-item">
              <div class="diag-item-title">${escapeHtml(dg.codigo || dg.nome || 'DGO')}</div>
              <div class="diag-item-meta">${escapeHtml(dg.site_codigo || dg.site_nome || '—')} • ${escapeHtml([dg.rack, dg.fila, dg.bastidor].filter(Boolean).join(' / ') || '—')}</div>
            </div>`)}
          ${renderRelationList('Cabos relacionados', model.cables || [], cb => `
            <div class="diag-item">
              <div class="diag-item-title">${escapeHtml(cb.codigo || cb.nome || 'Cabo')}</div>
              <div class="diag-item-meta">${escapeHtml(cb.tipo || '—')} • ${escapeHtml(cb.status || '—')} • ${escapeHtml(formatKm(cb.comprimento_m || cb.comprimento))}</div>
            </div>`)}
          ${renderRelationList('Incidentes associados', model.incidents || [], inc => `
            <div class="diag-item">
              <div class="diag-item-title">${escapeHtml(inc.titulo || 'Incidente')}</div>
              <div class="diag-item-meta">${escapeHtml(inc.status || '—')} • ${escapeHtml(inc.severidade || '—')} • ${escapeHtml(inc.site_afetado || '—')}</div>
            </div>`)}
        `;
      }
    }

    foundation?.audit?.('inventory.diagram.open', 'ok', { kind, id: entity.id || id }, 'info', 'Diagrama operacional aberto.');
    return model;
  }

  function init() {
    if (window.InventoryRuntime && window.InventoryRuntime.initialized) {
      return window.InventoryRuntime;
    }

    const runtime = {
      initialized: true,
      getSnapshot: snapshot,
      buildCableDiagramModel,
      buildCaixaDiagramModel,
      buildDgoDiagramModel,
      openOperationalDiagram
    };

    window.abrirDiagramaOperacional = openOperationalDiagram;
    window.InventoryRuntime = runtime;
    window.dispatchEvent(new CustomEvent('inventory:state', { detail: snapshot() }));
    log('info', 'inventory-runtime:init', snapshot());
    return runtime;
  }

  window.initInventoryRuntime = init;
})();
