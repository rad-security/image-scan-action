FROM public.ecr.aws/n8h5y2v5/rad-security/rad-image-scanner:0.0.4

# The base image already has grype and rad-image-scanner. We only need the
# tiny entrypoint shell that translates Action inputs into CLI flags.
COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
