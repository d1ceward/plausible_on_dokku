ARG PLAUSIBLE_VERSION="v1.3.0"

FROM plausible/analytics:$PLAUSIBLE_VERSION

CMD ["sh", "-c", "sleep 10 && /entrypoint.sh db createdb && /entrypoint.sh db migrate && /entrypoint.sh db init-admin && /entrypoint.sh run"]
