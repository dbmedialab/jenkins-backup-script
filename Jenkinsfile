pipeline {
    agent {
        label 'master'
    }
    stages {
        stage ("Clean") {
            steps {
                sh './makefile.sh clean'
            }
        }
        stage ("Backup") {
            steps {
                sh './makefile.sh backup'
            }
        }
        stage ("Verify") {
            steps {
                sh './makefile.sh verify'
            }
        }
        stage ("Upload") {
            steps {
                sh './makefile.sh upload_to_gs'
            }
        }
    }
}
