pipeline {
    agent {
        label 'master'
    }
    stages {
        stage ("Tools") {
            steps {
                tool 'make'
            }
        }
        stage ("Clean") {
            steps {
                sh 'make clean'
            }
        }
        stage ("Backup") {
            steps {
                sh 'make backup'
            }
        }
        stage ("Verify") {
            steps {
                sh 'make verify'
            }
        }
        stage ("Upload") {
            steps {
                sh 'make upload-to-gs'
            }
        }
    }
}
