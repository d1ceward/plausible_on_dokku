ARG PLAUSIBLE_VERSION="v1.4.4"

FROM plausible/analytics:$PLAUSIBLE_VERSION

EXPOSE 5000/tcp

CMD ["sh", "-c", "sleep 10 && /entrypoint.sh db createdb && /entrypoint.sh db migrate && /entrypoint.sh run"]
