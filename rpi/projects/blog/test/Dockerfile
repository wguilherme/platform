FROM jekyll/jekyll:4

WORKDIR /srv/jekyll

COPY . .

USER root

RUN gem install bundler:2.2.34 && \
  chown -R jekyll:jekyll /srv/jekyll

RUN bundle _2.2.34_; bundle; 

EXPOSE 4000

CMD ["jekyll", "serve","--trace", "--watch", "--host", "0.0.0.0"]