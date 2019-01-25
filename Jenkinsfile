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
                stash includes: 'run/backup.tar.gz', name: 'archive'
            }
        }
        
        stage ("Upload") {
            agent any
            steps {
                unstash 'archive'
                sh './makefile.sh upload_to_gs'
            }
        }
    }
}
