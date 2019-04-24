node {
  try {
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
      rvmSh 'yarn install --check-files --ignore-engines'
      rvmSh 'RAILS_ENV=test bundle exec rails db:migrate'
      rvmSh 'npm test'
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
