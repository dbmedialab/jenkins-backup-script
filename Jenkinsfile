pipeline {
    agent {
        label 'master'
    }
    stages {
        stage ("Clean") {
            sh 'make clean'
        }
        stage ("Backup") {
            sh 'make backup'
        }
        stage ("Verify") {
            sh 'make verify'
        }
        stage ("Upload") {
            sh 'make upload-to-gs'
        }
    }
}
