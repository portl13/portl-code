FROM 016615309443.dkr.ecr.us-west-2.amazonaws.com/base_java:v1.0.4

COPY ./target/rpm/RPMS/noarch/ /tmp/docker-rpm/

RUN rpm -ihv /tmp/docker-rpm/*

ADD docker/* /root/

RUN chmod +x /root/docker_entrypoint.sh

EXPOSE 2551

EXPOSE 9000

CMD ["/root/docker_entrypoint.sh"]