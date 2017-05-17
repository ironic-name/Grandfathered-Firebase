# Grandfathered-Firebase

This application is a companion project to the [Grandfathered sample app](https://github.com/ironic-name/Grandfathered-Application), an application used to demonstrate the idea of migrating users from an application backend (such as Parse which is used in this example) to another (in this instance, Firebase). 

> The application backends used in this example are not necessarily the only ones this will work for, but they are the two backends that I first applied this solution (admittedly badly) to.

The main file in this repo is the [firebase.rb](https://github.com/ironic-name/Grandfathered-Firebase/blob/master/firebase.rb) file which is used to take user records exported from Parse stored in [users.json](https://github.com/ironic-name/Grandfathered-Firebase/blob/master/users.json) and create two files, **auth.json** which will be imported to a firebase project as the users from the old backend, and **db.json** which contains relevant database information from the previous backend.

## Hypothesis

TODO

## Key elements of the migration script

 Besides correctly formatting the data as per the guidelines in [the Firebase CLI Reference](https://firebase.google.com/docs/cli/), the migration script's main purpose is to create a password for a user. This should be something computable, but not easily guessable. My solution, which may not be the best, albeit better than the first iteration of this solution, was to compute a hash based on a user's email address and the provided secret, with the secret as the key for HMAC_MD5 algorithm that I chose to use to encrypt with. 

This generates a password based on the combination of the user's email address and the provided secret.

    generate_password_hash(email + secret)

This is the method to generate the hex digest which will be used as a temporary password:

    # Generate basic MD5 digest
    def self.generate_password_hash(text)
      Digest::MD5.hexdigest(text)
    end

The result is then hashed using the HMAC_MD5 algorithm.

    hmac_digest(generate_password_hash(email + secret), secret)

This is the method used to compute the final hash:

    # Generate HMAC_MD5 digest
    def self.hmac_digest(data, secret)
      OpenSSL::HMAC.digest(OpenSSL::Digest.new('md5'), secret, data)
    end

Finally, the result is encoded as a base64 string, as per the Firebase CLI formatting requirements.

    Base64.encode64(hmac_digest(generate_password_hash(email + secret), secret))

## Pre-requisites:

> These are needed for the process to work:

* npm

* Firebase cli `npm install -g firebase-tools`

* A Firebase project


## Procedure

These are the steps to follow to migrate the users across

**Step 1:**

`cd containing_directory`

> Navigate into the containing project directory.

**Step 2:**

`irb -r ./firebase.rb`

> Open the ruby script that will generate the migration files.

**Step 3:**

`Firebase::FirebaseUserMigration::create_from_file_with_secret 'users.json','Secret'`

> Run the script, specifying the source file and the plain text secret. The secret can be anything. [This site](https://randomkeygen.com) generates such keys.

> The output of this script will look like this. **Note:**  the hash-key is base64 encoded, which will be needed later.
>
    "Starting..."
    "Reading file..."
    "Finished."
    "hash-key is: a2dIckhWeThSOA==\n"
    => true 


**Step 4:**

`firebase login`

> Login to Firebase CLI and run firebase init if not done

**Step 5:**

`firebase use grandfathered-98eff`

> Select the project.

**Step 6:**
 
`firebase auth:import auth.json --hash-algo=HMAC_MD5 --hash-key=U2VjcmV0`

> Import **auth.json** into Firebase, and specify the hashing algorithm used to encrypt the user's passwords. The hash-key is the base64 encoded string output in step 3.

**Step 7: **

>Import **db.json** into the Firebase live database by navigating to the console and importing the .json file.
