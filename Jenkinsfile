#!groovy

/**
 * https://github.com/jenkinsci/pipeline-examples/blob/master/jenkinsfile-examples/nodejs-build-test-deploy-docker-notify/Jenkinsfile
 */

node {


    currentBuild.result = "SUCCESS"

    try {

       stage('Checkout'){
            echo 'checkout...'
          checkout scm
       }

       stage('Test'){
         echo 'Testing...'
           run_test.sh

       }

       stage('Build Docker'){
           sh "#!/bin/bash \n" + "echo \"Hello from \$SHELL\""
            sh "pwd"
            sh "ls -la"
            echo 'build docker'
       }

       stage('Deploy'){

         echo 'Push to Repo'

       }

       stage('Cleanup'){

         echo 'cleanup'
       }



    }
    catch (err) {

        currentBuild.result = "FAILURE"

            echo 'err'

        throw err as java.lang.Throwable
    }

}
