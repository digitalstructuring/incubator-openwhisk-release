#!/usr/bin/env bash

function read_file() {
    cat $1
}

function json_by_key() {
    input=$1
    key=$2
    echo $input | jq ''.$key'' | sed -e 's/^"//' -e 's/"$//'
}

function import_key_verify_signature() {
    key_url=$1
    dir=$2
    cd $dir

    echo "Importing PGP keys"
    curl $key_url | gpg --import && \
    echo "[✓] GPG keys imported" \
      || { echo "[x] Failed to import GPG keys"; exit 1; }

    echo "Checking signatures and hashes of artifacts"
    for artifact in $(find * -type f \( -name '*.tar.gz' \) ); do
        # Check md5
        artifactMD5=$(gpg --print-md MD5 ${artifact})
        artifactMD5File=$(cat ${artifact}.md5)
        if [ "$artifactMD5" == "$artifactMD5File" ];then
            echo "[✓] MD5 verified for $artifact"
        else
            echo "[x] Unmatched MD5 for $artifact."; exit 1;
        fi

        # Check sha512
        artifactSha512=$(gpg --print-md SHA512 ${artifact})
        artifactSha512File=$(cat ${artifact}.sha512)
        if [ "$artifactSha512" == "$artifactSha512File" ];then
            echo "[✓] SHA512 verified for $artifact"
        else
            echo "[x] Unmatched SHA512 for $artifact."; exit 1;
        fi

        # Verify the signatures
        gpg --verify ${artifact}.asc ${artifact} && \
        echo "[✓] Signatures verified for $artifact" \
          || { echo "[x] Invalid signature for $artifact."; exit 1; }
    done
}