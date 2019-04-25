node{
  try {
    environment {
      //Use Pipeline Utility Steps plugin to read information from pom.xml into env variables
      TEST_DB_NAME = sh('jenkins_example_$(cat /dev/urandom | env LC_CTYPE=C tr -dc "a-zA-Z0-9" | fold -w 5 | head -n 1)')
      TEST_PORT = sh('$((3000 + RANDOM % 1000))')
    }
    stages {
      stage ('Checkout') {
        checkout scm
      }
      
      stage ('Install Gems') {
        rvmSh 'whoami'
        rvmSh 'which ruby'
        rvmSh 'whereis rvm'
        rvmSh 'which bundle'
        rvmSh 'bundle install --path vendor/bundle --full-index --verbose'
      }
      stage ('Run Unit tests'){
        sh 'printenv | sort'
        echo "${env.TEST_DB_NAME}"
        echo "${env.TEST_PORT}"
        rvmSh 'yarn install --check-files --ignore-engines'
        rvmSh "export TMP_TEST_DB=${env.TEST_DB_NAME} && RAILS_ENV=test bundle exec rails db:create && bundle exec rails db:migrate && PORT=${env.TEST_PORT} && PORT=$PORT CYPRESS_baseUrl=http://localhost:$PORT yarn start-test 'start_test' 'http://localhost:$PORT' cy:run && bundle exec rails db:drop"
      }
      
      
      if (env.BRANCH_NAME == 'master') {
        stage ('Accept Staging Deployment') {
          deploy = canDeploy()
          if(deploy) {
            stage 'Deploy to Staging'
              echo 'Will deploy to Staging'
          }
        }
      }
      def tag = sh(returnStdout: true, script: "git tag --contains | head -1").trim()
      if (tag) {
        stage ('Accept Production Deployment') {
          deploy = canDeploy()
          if(deploy) {
            stage 'Deploy to Production'
              echo 'Will deploy to Production'
          }
        }
      }
    }
  }
  catch(err) {
    notifyCulpritsOnEveryUnstableBuild()
    currentBuild.result = 'FAILURE'
    throw err
  }
}

def rvmSh(String cmd) {
    final RVM_HOME = '$PATH:/var/lib/jenkins/.rvm/bin'

    def sourceRvm = 'source /var/lib/jenkins/.rvm/scripts/rvm'
    def useRuby = "/var/lib/jenkins/.rvm/bin/rvm use --install 2.5.3"
    withEnv(["PATH=$PATH:/var/lib/jenkins/.rvm/bin"]) {
      // echo "${PATH}"
      sh "${sourceRvm}; ${useRuby}; $cmd"
    }
}

def notifyCulpritsOnEveryUnstableBuild() {
  step([
      $class                  : 'Mailer',
      notifyEveryUnstableBuild: true,
      recipients              : emailextrecipients([[$class: 'CulpritsRecipientProvider'], [$class: 'RequesterRecipientProvider']])
  ])
}

def canDeploy() {
    def deploy = input(id: 'deploy',
                                   message: 'Let\'s deploy?',
                                   parameters: [
                                     [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Deploy?', name: 'deploy']
                                   ])
    echo ('deploy:'+deploy)
  deploy
}
