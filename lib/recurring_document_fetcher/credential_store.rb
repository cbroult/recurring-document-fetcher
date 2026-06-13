# frozen_string_literal: true

require "psych/pure"
require "fileutils"
require "rbnacl"
require "base64"

module RecurringDocumentFetcher
  class CredentialStore
    DEFAULT_CREDENTIALS_PATH = File.join(
      Configuration::DEFAULT_CONFIG_DIR, "credentials.enc"
    )

    SALT_BYTES = 32
    KEY_BYTES = RbNaCl::SecretBox.key_bytes
    OPSLIMIT = 2**20
    MEMLIMIT = 2**24

    def initialize(path: DEFAULT_CREDENTIALS_PATH, passphrase: nil)
      @path = path
      @passphrase = passphrase
      @data = nil
    end

    def store(provider_name, credentials)
      load_data
      @data[provider_name.to_s] = credentials
      save_data
    end

    def retrieve(provider_name)
      load_data
      @data.fetch(provider_name.to_s) do
        raise AuthenticationError,
              "No credentials stored for '#{provider_name}'. " \
              "Run 'recurring-document-fetcher credentials store #{provider_name}'."
      end
    end

    def delete(provider_name)
      load_data
      @data.delete(provider_name.to_s)
      save_data
    end

    def list
      load_data
      @data.keys.sort
    end

    def exists?(provider_name)
      load_data
      @data.key?(provider_name.to_s)
    end

    private

    def passphrase
      @passphrase || ENV.fetch("RECURRING_DOCUMENT_FETCHER_PASSPHRASE") do
        raise AuthenticationError,
              "No passphrase provided. Set RECURRING_DOCUMENT_FETCHER_PASSPHRASE or pass --passphrase."
      end
    end

    def load_data
      return if @data

      if File.exist?(@path)
        encrypted = File.binread(@path)
        @data = decrypt(encrypted)
      else
        @data = {}
      end
    end

    def save_data
      FileUtils.mkdir_p(File.dirname(@path))
      encrypted = encrypt(@data)
      File.binwrite(@path, encrypted)
      File.chmod(0o600, @path)
    end

    def derive_key(salt)
      RbNaCl::PasswordHash.scrypt(
        passphrase,
        salt,
        OPSLIMIT,
        MEMLIMIT,
        KEY_BYTES
      )
    end

    def encrypt(data)
      salt = RbNaCl::Random.random_bytes(SALT_BYTES)
      key = derive_key(salt)
      box = RbNaCl::SecretBox.new(key)
      nonce = RbNaCl::Random.random_bytes(box.nonce_bytes)
      plaintext = Psych.dump(data)
      ciphertext = box.encrypt(nonce, plaintext)

      salt + nonce + ciphertext
    end

    def decrypt(blob)
      salt = blob[0, SALT_BYTES]
      key = derive_key(salt)
      box = RbNaCl::SecretBox.new(key)
      nonce = blob[SALT_BYTES, box.nonce_bytes]
      ciphertext = blob[(SALT_BYTES + box.nonce_bytes)..]

      plaintext = box.decrypt(nonce, ciphertext)
      Psych.safe_load(plaintext) || {}
    rescue RbNaCl::CryptoError
      raise AuthenticationError, "Failed to decrypt credentials. Wrong passphrase?"
    end
  end
end
