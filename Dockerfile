ARG ELIXIR_IMAGE="1.10.4-slim"

FROM elixir:$ELIXIR_IMAGE AS build

RUN mkdir /app
WORKDIR /app

# more specific than `COPY . .` to ensure clean _build and deps
COPY lib /app/lib
COPY mix.exs /app/
COPY mix.lock /app/

# install build deps
RUN export MIX_ENV=prod && \
    mix local.rebar --force && \
    mix local.hex --force

# install app deps
RUN export MIX_ENV=prod && \
    mix deps.get --only prod && \
    mix escript.build

# TODO: Could slim this down to not even need erlang

FROM elixir:$ELIXIR_IMAGE AS app

RUN useradd --create-home app
WORKDIR /home/app
USER app

RUN mkdir /home/app/kconnectex

COPY --from=build /app/kconnectex /home/app/kconnectex/kconnectex

ENTRYPOINT ["/home/app/kconnectex/kconnectex"]
