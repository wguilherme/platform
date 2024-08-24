FROM jekyll/jekyll:4

WORKDIR /srv/jekyll

COPY . .

USER root
RUN gem install bundler -v 2.2.34 && \
  chown -R jekyll:jekyll /srv/jekyll

RUN bundle install

EXPOSE 4000

CMD ["jekyll", "serve", "--watch", "--host", "0.0.0.0"]