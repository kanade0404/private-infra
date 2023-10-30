FROM hashicorp/terraform:1.6.2 AS builder

FROM google/cloud-sdk:452.0.1

COPY --from=builder /bin/terraform /bin/terraform

RUN apt update && \
    apt install unzip && \
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
    curl -Lso tfsec https://github.com/tfsec/tfsec/releases/download/v1.15.4/tfsec-linux-amd64 && \
    chmod +x tfsec && \
    mv tfsec /usr/local/bin/tfsec

ENTRYPOINT ["/bin/bash"]
