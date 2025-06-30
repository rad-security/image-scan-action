FROM public.ecr.aws/n8h5y2v5/rad-security/image-scan:v0.0.4

RUN apk add --no-cache jq

COPY entrypoint.sh /entrypoint.sh
COPY output_with_summary.tmpl /output_with_summary.tmpl

ENTRYPOINT ["/entrypoint.sh"]
