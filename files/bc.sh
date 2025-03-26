#!/bin/bash

# Nama file backup
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ZIP_FILE="mora_$TIMESTAMP.zip"
INSTALL_SCRIPT="install.sh"
LOG_FILE="log.txt"

# Tambahkan log baru dengan timestamp
echo "[$TIMESTAMP] Event: Backup dimulai" >> "$LOG_FILE"
cat "$LOG_FILE"

# 1. Zip folder mora
zip -r "$ZIP_FILE" mora/

# 2. Konfigurasi API
TELEGRAM_BOT_TOKEN="6483981163:AAF9hMhavGJNB86Cdab9Cy8O2ZUCXuj5-xE"
TELEGRAM_CHAT_ID="5888076846"  # Ganti dengan chat ID Telegram kamu
GITHUB_USER="KerenBetGw"
GITHUB_REPO="files"
GITHUB_TOKEN="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"  # Simpan di ENV jika memungkinkan
FILE_PATH_ZIP="uploads/mora.zip"
FILE_PATH_INSTALL="uploads/install.sh"
LOCAL_FILE_ZIP="$ZIP_FILE"
COMMIT_MSG="Backup $ZIP_FILE via API"

output=$(curl --upload-file "$ZIP_FILE" https://bashupload.com 2>/dev/null)

# Ekstrak URL download
DOWNLOAD_URL=$(echo "$output" | grep -o 'https://bashupload.com/[^ ]*' | head -1)

if [[ "$DOWNLOAD_URL" != "null" && -n "$DOWNLOAD_URL" ]]; then
    echo "✅ Backup berhasil diupload: $DOWNLOAD_URL"
    MESSAGE="Backup berhasil diupload: $DOWNLOAD_URL"

    # 6. Buat file install.sh
    cat <<EOF > "$INSTALL_SCRIPT"
#!/bin/bash
sudo apt update -y
sudo curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt install nodejs -y
sudo apt install unzip jq -y
sudo wget -O /root/mora.zip $DOWNLOAD_URL
sudo unzip /root/mora.zip -d /root/mora/
sudo rm /root/mora.zip
sudo chmod +x /root/mora/start.sh
sudo screen -dmS mora /root/mora/start.sh
EOF

    # 7. Ambil SHA file install.sh jika sudah ada
    SHA_INSTALL=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                          -H "Accept: application/vnd.github.v3+json" \
                          "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$FILE_PATH_INSTALL" | jq -r .sha)

    # Encode isi file install.sh dalam base64
    CONTENT_INSTALL=$(base64 -w 0 "$INSTALL_SCRIPT")

    # Buat JSON payload untuk install.sh
    if [ "$SHA_INSTALL" = "null" ] || [ -z "$SHA_INSTALL" ]; then
        JSON_PAYLOAD_INSTALL=$(jq -n --arg msg "Menambahkan install.sh" --arg content "$CONTENT_INSTALL" '{
            message: $msg,
            content: $content
        }')
    else
        JSON_PAYLOAD_INSTALL=$(jq -n --arg msg "Memperbarui install.sh" --arg content "$CONTENT_INSTALL" --arg sha "$SHA_INSTALL" '{
            message: $msg,
            content: $content,
            sha: $sha
        }')
    fi

    # 8. Upload install.sh ke GitHub
    RESPONSE_INSTALL=$(curl -s -X PUT -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "$JSON_PAYLOAD_INSTALL" \
        "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$FILE_PATH_INSTALL")

    INSTALL_URL=$(echo "$RESPONSE_INSTALL" | jq -r '.content.download_url')

    if [[ "$INSTALL_URL" != "null" && -n "$INSTALL_URL" ]]; then
        MESSAGE+="
        
Install script tersedia: $INSTALL_URL"
    else
        MESSAGE+="\n❌ Gagal upload install.sh ke GitHub!"
    fi
else
    echo "❌ Gagal upload backup ke GitHub!"
    MESSAGE="Gagal upload backup ke GitHub!"
fi

# 9. Kirim notifikasi ke Telegram
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="$MESSAGE"

# 10. Hapus file lokal (opsional)
rm -f "$ZIP_FILE" "$INSTALL_SCRIPT"