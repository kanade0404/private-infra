FROM hashicorp/terraform:1.9.5 AS terraform

FROM ubuntu:24.04 AS base
RUN apt update && \
    apt install -y unzip curl && \
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
    curl -Lso tfsec https://github.com/tfsec/tfsec/releases/download/v1.15.4/tfsec-linux-amd64 && \
    chmod +x tfsec && \
    mv tfsec /usr/local/bin/tfsec

FROM google/cloud-sdk:486.0.0

COPY --from=terraform /bin/terraform /bin/terraform
COPY --from=base /usr/local/bin/tflint /usr/local/bin/tflint
COPY --from=base /usr/local/bin/tfsec /usr/local/bin/tfsec

CMD ["bash"]
