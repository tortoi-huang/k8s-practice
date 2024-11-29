# TODO 应该将此文件保持到configmap 并挂载到 postgresql 的 primary.initdb.scriptsConfigMap 配置项
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-postgres}" <<-EOSQL
CREATE USER gitlab with password 'Gl1234';
CREATE DATABASE gitlab_db;
GRANT ALL PRIVILEGES ON DATABASE gitlab_db TO gitlab;
\c gitlab_db
GRANT ALL PRIVILEGES ON SCHEMA public TO gitlab;
EOSQL