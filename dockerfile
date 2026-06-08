# 1. Usando a imagem oficial e correta da Astral para o Python 3.12
FROM astral/uv:python3.12-bookworm-slim

# Essa variável de ambiente é usada para controlar se o Python deve
# gravar arquivos de bytecode (.pyc) no disco. 1 = Não, 0 = Sim
ENV PYTHONDONTWRITEBYTECODE=1

# Define que a saída do Python será exibida imediatamente no console ou em
# outros dispositivos de saída, sem ser armazenada em buffer.
# Em resumo, você verá os outputs do Python em tempo real.
ENV PYTHONUNBUFFERED=1

# Define que o uv vai trabalhar no escopo global do sistema (dentro do container)
ENV UV_PROJECT_ENVIRONMENT=/usr/local

# Essa variável de ambiente é usada para controlar se o uv deve ou não
# instalar as dependências de desenvolvimento. 1 = Não, 0 = Sim
# ENV UV_NO_DEV=1

# Essa variável de ambiente é usada para controlar se o uv deve ou não
# respeitar o arquivo de bloqueio (uv.lock) ao instalar as dependências.
# 1 = Sim, 0 = Não
ENV UV_LOCKED=1

# Adiciona a pasta scripts ao $PATH do container.
ENV PATH="/scripts:$PATH"

# Entra na pasta djangoapp no container
WORKDIR /djangoapp

# A porta 8000 estará disponível para conexões externas ao container
# É a porta que vamos usar para o Django.
EXPOSE 8000

# RUN executa comandos em um shell dentro do container para construir a imagem.
# Instala dependências nativas para o psycopg2 (Postgres)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev && \
    rm -rf /var/lib/apt/lists/* && \
    # Cria o usuário de segurança
    adduser --disabled-password --no-create-home duser && \
    # Cria as pastas para arquivos estáticos e uploads (media)
    mkdir -p /data/web/static && \
    mkdir -p /data/web/media && \
    # Passa o dono dessas pastas para o duser
    chown -R duser:duser /data/web/static && \
    chown -R duser:duser /data/web/media && \
    chmod -R 755 /data/web/static && \
    chmod -R 755 /data/web/media



# Copia APENAS os arquivos de especificação de pacotes primeiro
# (Só reexecuta se o pyproject/uv.lock mudar)
# Isso garante que o Docker use o cache se você não alterou as dependências
COPY pyproject.toml uv.lock* /djangoapp/

# O uv instala o Django/Postgres puro e o Docker salva isso num cache pesado.
# Como o código do seu app não está aqui, usamos a tag para o uv não reclamar.
RUN uv sync --no-install-project --no-dev

# Copia a pasta "djangoapp" e "scripts" para dentro do container.
# (Muda o tempo todo, mas roda em menos de 1 segundo)
COPY ./djangoapp /djangoapp
COPY ./scripts /scripts

# Agora que os arquivos existem, aplicamos as permissões necessárias
RUN chmod -R +x /scripts && \
    chown -R duser:duser /djangoapp

# Sincronização final do projeto dentro do container
RUN uv sync --no-dev

# Usuário de segurança desativado localmente para evitar dores de cabeça no WSL.
# Descomente a linha abaixo apenas quando for subir para produção (AWS/DigitalOcean).
# USER duser

# Executa o arquivo scripts/commands.sh
CMD ["commands.sh"]
