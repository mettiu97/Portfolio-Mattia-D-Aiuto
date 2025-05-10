USE banca;
-- Inizio calcolando l'età partendo dalla data di nascita e salvandola in una tabella temporanea.
-- Utilizzo il comando drop table per poter ricreare all'occorrenza la tabella temporanea senza incorrere nell'errore tabella già esistente
DROP TABLE IF EXISTS temp_eta;
CREATE TEMPORARY TABLE temp_eta AS
SELECT 
    c.id_cliente,
    TIMESTAMPDIFF(YEAR, c.data_nascita, CURDATE()) AS età
FROM banca.cliente c;
SELECT * FROM temp_eta;

-- Si associa ogni cliente ai conti che possiede utlizzando sempre una tabella tempooranea
DROP TABLE IF EXISTS temp_clienti_conti;
CREATE TEMPORARY TABLE temp_clienti_conti AS
SELECT 
    e.id_cliente,
    e.età,
    co.id_conto
FROM temp_eta e
LEFT JOIN banca.conto co ON e.id_cliente = co.id_cliente;
SELECT * FROM temp_clienti_conti limit 10;

-- Si uniscono le transazioni ai conti per collegarle ai clienti.
DROP TABLE IF EXISTS temp_clienti_transazioni;
CREATE TEMPORARY TABLE temp_clienti_transazioni AS
SELECT
    cc.id_cliente,
    cc.età,
    cc.id_conto,
    t.importo,
    t.id_tipo_trans
FROM temp_clienti_conti cc
LEFT JOIN banca.transazioni t ON cc.id_conto = t.id_conto;
SELECT * FROM temp_clienti_transazioni;

-- Adesso collego ogni transazione alla sua tipologia.
DROP TABLE IF EXISTS temp_transazioni;
CREATE TEMPORARY TABLE temp_transazioni AS
SELECT 
    ct.id_cliente,
    ct.età,
    ct.id_conto,
    ct.importo,
    tt.id_tipo_transazione
FROM temp_clienti_transazioni ct
LEFT JOIN banca.tipo_transazione tt ON ct.id_tipo_trans = tt.id_tipo_transazione;
SELECT * FROM temp_transazioni LIMIT 10;

/* Adesso procedo al calcoloo degli indicatori sulle transazioni 
calcolando il numero di transazioni in entrata e uscita per cliente
e l'importo totale delle transazioni in entrata e uscita per cliente.*/
DROP TABLE IF EXISTS temp_indicatori;
CREATE TEMPORARY TABLE temp_indicatori AS
SELECT 
    id_cliente,
    COUNT(CASE WHEN id_tipo_transazione BETWEEN 0 AND 2 THEN 1 END) AS num_transazioni_entrata,
    COUNT(CASE WHEN id_tipo_transazione BETWEEN 3 AND 7 THEN 1 END) AS num_transazioni_uscita,
    SUM(CASE WHEN id_tipo_transazione BETWEEN 0 AND 2 THEN importo ELSE 0 END) AS importo_totale_entrata,
    SUM(CASE WHEN id_tipo_transazione BETWEEN 3 AND 7 THEN importo ELSE 0 END) AS importo_totale_uscita
FROM temp_transazioni
GROUP BY id_cliente;
SELECT * FROM temp_indicatori;

/* Adesso calcolo gli indicatori sui conti
cioè il numero totale di conti posseduti da ogni cliente
e il numero di conti per ogni tipologia di conto. */
DROP TABLE IF EXISTS temp_conti_cliente;
CREATE TEMPORARY TABLE temp_conti_cliente AS
SELECT 
    c.id_cliente,
    COUNT(c.id_conto) AS num_conti_totale
FROM conto c
GROUP BY c.id_cliente;

DROP TABLE IF EXISTS temp_conti_tipo_cliente;
CREATE TEMPORARY TABLE temp_conti_tipo_cliente AS
SELECT 
    c.id_cliente,
    tc.desc_tipo_conto,
    COUNT(c.id_conto) AS num_conti_per_tipo
FROM conto c
JOIN tipo_conto tc ON c.id_tipo_conto = tc.id_tipo_conto
GROUP BY c.id_cliente, tc.desc_tipo_conto;
SELECT * FROM temp_conti_cliente;
SELECT * FROM temp_conti_tipo_cliente;

SELECT 
    c.id_cliente, 
    num_conti_totale, 
    tc.desc_tipo_conto, 
    num_conti_per_tipo
FROM temp_conti_cliente c
LEFT JOIN temp_conti_tipo_cliente tc ON c.id_cliente = tc.id_cliente;

-- Adesso calcolo gli Indicatori sulle Transazioni per Tipologia di Conto
DROP TABLE IF EXISTS temp_transazioni_tipo_conto;
CREATE TEMPORARY TABLE temp_transazioni_tipo_conto AS
SELECT 
    c.id_cliente,

    -- Numero di transazioni in entrata per ogni tipo di conto
    SUM(CASE WHEN tc.id_tipo_conto = 0 AND t.id_tipo_trans BETWEEN 0 AND 2 THEN 1 ELSE 0 END) AS num_trans_entrata_Conto_Base,
    SUM(CASE WHEN tc.id_tipo_conto = 1 AND t.id_tipo_trans BETWEEN 0 AND 2 THEN 1 ELSE 0 END) AS num_trans_entrata_Conto_Business,
    SUM(CASE WHEN tc.id_tipo_conto = 2 AND t.id_tipo_trans BETWEEN 0 AND 2 THEN 1 ELSE 0 END) AS num_trans_entrata_Conto_Privati,
    SUM(CASE WHEN tc.id_tipo_conto = 3 AND t.id_tipo_trans BETWEEN 0 AND 2 THEN 1 ELSE 0 END) AS num_trans_entrata_Conto_Famiglie,

    -- Numero di transazioni in uscita per ogni tipo di conto
    SUM(CASE WHEN tc.id_tipo_conto = 0 AND t.id_tipo_trans BETWEEN 3 AND 7 THEN 1 ELSE 0 END) AS num_trans_uscita_Conto_Base,
    SUM(CASE WHEN tc.id_tipo_conto = 1 AND t.id_tipo_trans BETWEEN 3 AND 7 THEN 1 ELSE 0 END) AS num_trans_uscita_Conto_Business,
    SUM(CASE WHEN tc.id_tipo_conto = 2 AND t.id_tipo_trans BETWEEN 3 AND 7 THEN 1 ELSE 0 END) AS num_trans_uscita_Conto_Privati,
    SUM(CASE WHEN tc.id_tipo_conto = 3 AND t.id_tipo_trans BETWEEN 3 AND 7 THEN 1 ELSE 0 END) AS num_trans_uscita_Conto_Famiglie,

    -- Importo transato in entrata per ogni tipo di conto
    SUM(CASE WHEN tc.id_tipo_conto = 0 AND t.id_tipo_trans BETWEEN 0 AND 2 THEN t.importo ELSE 0 END) AS importo_entrata_Conto_Base,
    SUM(CASE WHEN tc.id_tipo_conto = 1 AND t.id_tipo_trans BETWEEN 0 AND 2 THEN t.importo ELSE 0 END) AS importo_entrata_Conto_Business,
    SUM(CASE WHEN tc.id_tipo_conto = 2 AND t.id_tipo_trans BETWEEN 0 AND 2 THEN t.importo ELSE 0 END) AS importo_entrata_Conto_Privati,
    SUM(CASE WHEN tc.id_tipo_conto = 3 AND t.id_tipo_trans BETWEEN 0 AND 2 THEN t.importo ELSE 0 END) AS importo_entrata_Conto_Famiglie,

    -- Importo transato in uscita per ogni tipo di conto
    SUM(CASE WHEN tc.id_tipo_conto = 0 AND t.id_tipo_trans BETWEEN 3 AND 7 THEN t.importo ELSE 0 END) AS importo_uscita_Conto_Base,
    SUM(CASE WHEN tc.id_tipo_conto = 1 AND t.id_tipo_trans BETWEEN 3 AND 7 THEN t.importo ELSE 0 END) AS importo_uscita_Conto_Business,
    SUM(CASE WHEN tc.id_tipo_conto = 2 AND t.id_tipo_trans BETWEEN 3 AND 7 THEN t.importo ELSE 0 END) AS importo_uscita_Conto_Privati,
    SUM(CASE WHEN tc.id_tipo_conto = 3 AND t.id_tipo_trans BETWEEN 3 AND 7 THEN t.importo ELSE 0 END) AS importo_uscita_Conto_Famiglie

FROM banca.transazioni t
JOIN banca.conto c ON t.id_conto = c.id_conto
JOIN banca.tipo_conto tc ON c.id_tipo_conto = tc.id_tipo_conto

GROUP BY c.id_cliente;
SELECT * FROM temp_transazioni_tipo_conto;

-- Infine procedo alla creazione della tabella denormalizzata unendo tutte le tabelle temporanee create
-- Ho preferito creare più tabelle temporanee e fare il join punto per punto per far vedere meglio lo sviluppo di tutti i punti del progetto
DROP TABLE IF EXISTS tabella_denormalizzata;
CREATE TEMPORARY TABLE tabella_denormalizzata AS
SELECT 
    e.id_cliente, 
    e.età, 
    COALESCE(cc.num_conti_totale, 0) AS num_conti_totale,
    -- Utilizzo il comando coalesce per gestire i valori null e sostituirli con zero
    
	-- Numero di conti per tipologia
    COALESCE(tc.num_conti_per_tipo_0, 0) AS num_conti_Conto_Base,
    COALESCE(tc.num_conti_per_tipo_1, 0) AS num_conti_Conto_Business,
    COALESCE(tc.num_conti_per_tipo_2, 0) AS num_conti_Conto_Privati,
    COALESCE(tc.num_conti_per_tipo_3, 0) AS num_conti_Conto_Famiglie,

	-- Numero di transazioni in entrata per tipologia di conto
    COALESCE(ttc.num_trans_entrata_Conto_Base, 0) AS num_trans_entrata_Conto_Base,
    COALESCE(ttc.num_trans_entrata_Conto_Business, 0) AS num_trans_entrata_Conto_Business,
    COALESCE(ttc.num_trans_entrata_Conto_Privati, 0) AS num_trans_entrata_Conto_Privati,
    COALESCE(ttc.num_trans_entrata_Conto_Famiglie, 0) AS num_trans_entrata_Conto_Famiglie,
    
    -- Numero di transazioni in uscita per tipologia di conto
    COALESCE(ttc.num_trans_uscita_Conto_Base, 0) AS num_trans_uscita_Conto_Base,
    COALESCE(ttc.num_trans_uscita_Conto_Business, 0) AS num_trans_uscita_Conto_Business,
    COALESCE(ttc.num_trans_uscita_Conto_Privati, 0) AS num_trans_uscita_Conto_Privati,
    COALESCE(ttc.num_trans_uscita_Conto_Famiglie, 0) AS num_trans_uscita_Conto_Famiglie,
    
    -- Importo transato in entrata per tipologia di conto
    COALESCE(ttc.importo_entrata_Conto_Base, 0) AS importo_entrata_Conto_Base,
    COALESCE(ttc.importo_entrata_Conto_Business, 0) AS importo_entrata_Conto_Business,
    COALESCE(ttc.importo_entrata_Conto_Privati, 0) AS importo_entrata_Conto_Privati,
    COALESCE(ttc.importo_entrata_Conto_Famiglie, 0) AS importo_entrata_Conto_Famiglie,
    
    -- Importo transato in uscita per tipologia di conto
    COALESCE(ttc.importo_uscita_Conto_Base, 0) AS importo_uscita_Conto_Base,
    COALESCE(ttc.importo_uscita_Conto_Business, 0) AS importo_uscita_Conto_Business,
    COALESCE(ttc.importo_uscita_Conto_Privati, 0) AS importo_uscita_Conto_Privati,
    COALESCE(ttc.importo_uscita_Conto_Famiglie, 0) AS importo_uscita_Conto_Famiglie,

    -- Importo totale transato in entrata ed in uscita
    COALESCE(ti.importo_totale_entrata, 0) AS importo_totale_entrata,
    COALESCE(ti.importo_totale_uscita, 0) AS importo_totale_uscita

FROM temp_eta e
LEFT JOIN temp_conti_cliente cc ON e.id_cliente = cc.id_cliente

-- Numero conti per tipo
LEFT JOIN (
    SELECT 
        c.id_cliente,
        SUM(CASE WHEN tc.id_tipo_conto = 0 THEN 1 ELSE 0 END) AS num_conti_per_tipo_0,
        SUM(CASE WHEN tc.id_tipo_conto = 1 THEN 1 ELSE 0 END) AS num_conti_per_tipo_1,
        SUM(CASE WHEN tc.id_tipo_conto = 2 THEN 1 ELSE 0 END) AS num_conti_per_tipo_2,
        SUM(CASE WHEN tc.id_tipo_conto = 3 THEN 1 ELSE 0 END) AS num_conti_per_tipo_3
    FROM banca.conto c
    JOIN banca.tipo_conto tc ON c.id_tipo_conto = tc.id_tipo_conto
    GROUP BY c.id_cliente
) tc ON e.id_cliente = tc.id_cliente

-- Tabella da cui ricavo le transazioni per tipo di conto
LEFT JOIN temp_transazioni_tipo_conto ttc ON e.id_cliente = ttc.id_cliente

-- Tabella da cui ricavo l'importo totale entrata/uscita
LEFT JOIN temp_indicatori ti ON e.id_cliente = ti.id_cliente;
SELECT * FROM tabella_denormalizzata;


