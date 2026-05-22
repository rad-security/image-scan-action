FROM ghcr.io/rad-security/image-scanner:latest

# The base image already has grype and rad-image-scanner. We only need the
# tiny entrypoint shell that translates Action inputs into CLI flags.
USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
