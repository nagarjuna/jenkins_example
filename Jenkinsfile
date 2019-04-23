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
      stage ('Prepare Build') {
        echo 'Compile assets'
        echo 'Compress the build'
        echo 'Push the build to Artifactory'
      }
      stage ('Accept Staging Deployment') {
        deployToStaging = canDeployToStaging()
        if(deployToStaging) {
          stage 'Deploy to Staging'
            echo 'Will deploy to Staging'
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

def canDeployToStaging() {
    def deployToStaging = input(id: 'deployToStaging',
                                   message: 'Let\'s deploy to Staging?',
                                   parameters: [
                                     [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Deploy?', name: 'deployToStaging']
                                   ])
    echo ('deployToStaging:'+deployToStaging)
  deployToStaging
}
