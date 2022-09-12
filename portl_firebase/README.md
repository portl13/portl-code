Firebase Admin for PORTL
===

Required
---
- Node 8

Setup
---

- Install Firebase CLI globally using ```npm install -g firebase-tools```

- Sign into Firebase account using ```firebase login``` A web browser will open for you to authenticate.

- Clone repo at *ssh://git@stash.concentricsky.com/portl/firebase.git*

- Run ```npm install```

- Run ```firebase init``` . Select the staging project, *portl-dev-1d042*, as the default project. Select the options for deploying realtime database rules and deploying cloud functions. Use default databse rules name, but do not let it overwrite the existing file. Select Typescript when given the option. Say yes to the TSLint option. Do not allow the functions-related files to be overwritten. Allow installation of dependencies.

- Add ```\cp -r data_model/* functions/src``` to *firebase.json* predeploy array in the first position. **Note** If editing model files, edit the files that are included in the */data_model* folder (not the versions that are copied for compilation)

Run
---

- Refer to the root level *package.json* for available scripts.
- Refer to *https://firebase.google.com/docs/cli/* for more information on features of Firebase CLI.