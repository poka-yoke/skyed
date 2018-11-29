FROM ruby:2.1.5

RUN mkdir ~/.ssh && ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts; gem install bundler

WORKDIR /skyed

COPY Gemfile Gemfile.lock /skyed/

RUN bundle install

COPY . /skyed

ENTRYPOINT ["bin/skyed"]
