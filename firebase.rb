require 'json'
require 'digest/md5'
require 'openssl'
require 'base64'

module Firebase
  class FirebaseUserMigration

    def self.create_from_file_with_secret(path, secret)
      in_file = path
      if valid_file?(in_file)
        unless secret.nil? || secret.empty?
          p 'Starting...'
          # Script file variables
          in_file = path
          out_file_auth = 'auth.json'
          out_file_db = 'db.json'

          auth = Array.new
          db = Hash.new
          list = Array.new

          p 'Reading file...'
          file = File.read(path)
          users = JSON.parse(file)
          uid = 0

          users['results'].each do |child|
            uid += 1
            username = child['username']
            email = child['email']

            unless is_a_valid_email?(email)
              email = username.gsub(/\s+/, "") + "@grandfathered.app"
            end

            # Add user to database file
            tempDB = {
              uid => child
            }

            # Add user authentication to authentication file
            tempAuth = {
              "localId" => uid,
              "email" => email,
              "passwordHash" => Base64.encode64(hmac_digest(generate_password_hash(email + secret), secret)),
              "displayName" => username
            }

            auth << tempAuth

            list << {"email" => email}

            db.merge!(tempDB)
          end

          finalAuth = {"users" => auth}
          finalDB = {"users" => db, "migrated_users" => list}

          File.open(out_file_db, "w") { |io|  io << JSON.pretty_generate(finalDB) }
          File.open(out_file_auth, "w") { |io| io << JSON.pretty_generate(finalAuth) }

          p 'Finished.'

          return true;
        end
      else
        p 'The file is invalid. Please  ensure that the path is valid and try again'
        return false;
      end
    end

    # Generate basic MD5 digest
    def self.generate_password_hash(text)
      Digest::MD5.hexdigest(text)
    end

    # Generate HMAC_MD5 digest
    def self.hmac_digest(data, secret)
      OpenSSL::HMAC.digest(OpenSSL::Digest.new('md5'), secret, data)
    end

    # Check the validity of a file
    def self.valid_file?(path)
      File.exist?(path) && File.extname(path) == '.json'
    end

    # Check validity of an email address
    def self.is_a_valid_email?(email)
      (email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    end
  end
end
