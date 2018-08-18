# IPRx

## Setup

Note that all the instructions that follow assume you have access to the repository and that you are authorised with SSH to the repo at civicledger.visualstudio.com. They also assume at least a basic familiarity with a command-line terminal, including Git. Node including NPM must be available.

Instructions should be identical cross-platform, but Windows is not a tested platform.

1. Checkout this repository. You must check it out to a directory that does **not** have a space in the filename, unlike the repo. You can do this as, for example: 
    ```
    git clone ssh://civicledger@vs-ssh.visualstudio.com:22/IP%20Australia/_ssh/IP%20Australia IPAustralia
    ```
2. Navigate to that directory: 
    ```
    cd IPAustralia
    ```
3. This is the root directory for the project, which is split into two pieces, a web frontend and a testing backend. The latter is required for the frontend to work so we can do that first.
    ```
    cd iprx-api
    ```
4. Use NPM to install dependencies. Note that this is a relatively long process and can take several inutes
    ```
    npm install
    ```
5. Build all of the files into the working software.
    ```
    npm install
    npm run build
    ```
    This should execute a short series of file actions, largely invisble to the user, but there should be no errors.
6. Navigate to the `web` directory from the `iprx-api` directory.
    ```
    cd ../web
    ```
7. Install Angular and related dependencies
    ```
    npm install
    ```
8. Build and serve the Angular application
    ```
    npm run-script ng serve --open
    ```
9. Open the browser at http://localhost:4200 and the application should be working.


