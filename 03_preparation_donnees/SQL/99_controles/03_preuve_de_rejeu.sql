-- ============================================================
-- PREUVE DE REPRODUCTIBILITÉ
-- ============================================================
-- ⚠ CE SCRIPT DÉTRUIT L'INTÉGRALITÉ DE LA BASE.
--
-- Objectif : vérifier que le pipeline se reconstruit à
-- l'identique depuis les seuls CSV bruts. C'est ce qui
-- distingue un pipeline d'une suite de manipulations.
--
-- Aucun risque : les CSV sources ne sont pas touchés.
--
-- Après exécution, rejouer dans cet ordre :
--   1. SQL/01_raw/01_create_tables_raw.sql
--   2. PYTHON/chargement.py
--   3. SQL/02_staging/01_create_tables_staging.sql
--   4. SQL/03_intermediate/01_intermediate.sql
--   5. PYTHON/distances.py
--   6. SQL/04_mart/02_mart_orders.sql
--   7. SQL/04_mart/03_mart_sellers.sql
--   8. SQL/99_controles/02_recette.sql
--
-- RÉSULTAT DU TEST : chiffres identiques (96 447 / 1 323 /
-- 6,77 %). Pipeline reproductible ✅
-- ============================================================
DROP SCHEMA raw CASCADE;
DROP SCHEMA staging CASCADE;
DROP SCHEMA intermediate CASCADE;
DROP SCHEMA mart CASCADE;

CREATE SCHEMA raw;
CREATE SCHEMA staging;
CREATE SCHEMA intermediate;
CREATE SCHEMA mart;