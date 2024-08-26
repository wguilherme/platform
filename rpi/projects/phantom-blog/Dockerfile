FROM ruby:3.1-slim

WORKDIR /srv/jekyll

COPY . .

COPY imported/* /_posts/

# Instalar dependências necessárias
RUN apt-get update && apt-get install -y \
  build-essential \
  zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

# Criar um usuário não-root
# RUN useradd -m jekyll
USER root

RUN gem install bundler:2.2.34 && \
  chown -R root:root /srv/jekyll

RUN bundle _2.2.34_; bundle; 

EXPOSE 4000

CMD ["jekyll", "serve", "--trace", "--watch", "--host", "0.0.0.0"]