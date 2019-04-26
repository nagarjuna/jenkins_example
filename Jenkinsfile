pipeline {
  agent any
  environment {
    TEST_DB_NAME = "jenkins_example_${ sh(returnStdout: true, script: 'echo cat /dev/urandom | env LC_CTYPE=C tr -dc \"a-zA-Z0-9\" | fold -w 5 | head -n 1') }"
    TEST_PORT = sh(returnStdout: true, script: 'echo $((3000 + RANDOM % 1000))')
  }
  stages {
    stage ('Install Gems') {
      steps {
        sh 'printenv | sort'
        sh "echo ${env.TEST_DB_NAME}"
        // sh 'whoami'
        // sh 'which ruby'
        // sh 'ruby -v'
        rvmSh 'which bundle'
        rvmSh 'bundle install --path vendor/bundle --full-index --verbose'
      }
    }
    stage ('Run Unit tests'){
      steps {
        sh 'printenv | sort'
        rvmSh 'yarn install --check-files --ignore-engines'
        rvmSh "export TMP_TEST_DB=${env.TMP_TEST_DB} && RAILS_ENV=test bundle exec rails db:create && RAILS_ENV=test bundle exec rails db:migrate"
        rvmSh "export PORT=${env.TEST_PORT} && PORT=${env.TEST_PORT} CYPRESS_baseUrl=http://localhost:${env.TEST_PORT} yarn start-test 'start_test' 'http://localhost:${env.TEST_PORT}' cy:run"
      }
    }

    stage ('Accept Staging Deployment') {
      when {
        expression {
          return env.BRANCH_NAME == 'master' && canDeploy()
        }
        beforeAgent true
      }
      failFast true
      parallel {
        stage ('Deploy to Staging Web'){
          steps {
            echo 'Will deploy to Staging Web'
          }
        }
        stage ('Deploy to Staging BG'){
          steps {
            echo 'Will deploy to Staging BG'
          }
        }
      }
    }
    stage ('Accept Production Deployment') {
      when {
        expression {
          return sh(returnStdout: true, script: "git tag --contains | head -1").trim() != null && canDeploy()
        }
        beforeAgent true
      }
      failFast true
      parallel {
        stage ('Deploy to Production'){
          steps {
            echo 'Will deploy to Production'
          }
        }
      }
    }


    // if (env.BRANCH_NAME == 'master') {
    //   stage ('Accept Staging Deployment') {
    //     deploy = canDeploy()
    //     if(deploy) {
    //       stage 'Deploy to Staging'
    //         echo 'Will deploy to Staging'
    //     }
    //   }
    // }
    // def tag = sh(returnStdout: true, script: "git tag --contains | head -1").trim()
    // if (tag) {
    //   stage ('Accept Production Deployment') {
    //     deploy = canDeploy()
    //     if(deploy) {
    //       stage 'Deploy to Production'
    //         echo 'Will deploy to Production'
    //     }
    //   }
    // }
  }
  post {
      always {
        rvmSh "export TMP_TEST_DB=${env.TMP_TEST_DB} && RAILS_ENV=test bundle exec rails db:drop"
      }
      // failure {
      //     mail to: nagarjuna.rachaneni@vandapharma.com, subject: 'The Pipeline failed :('
      // }
  }
}

def rvmSh(String cmd) {
  def sourceRvm = 'source /var/lib/jenkins/.rvm/scripts/rvm'
  def useRuby = "/var/lib/jenkins/.rvm/bin/rvm use --install 2.5.3"
  sh "${sourceRvm}; ${useRuby}; $cmd"
}

def canDeploy() {
  when {
    expression {
      boolean deploy = false
      try {
        timeout(time: 1, unit: 'DAYS') {
          input { message: 'Let\'s deploy?' }
          deploy = true
        }
      } catch (final ignore) {
        deploy = false
      }
      echo ('deploy:'+deploy)
      return deploy
    }
  }
}



// node{
//   withEnv(["TMP_TEST_DB=jenkins_example_${env.BUILD_ID}", "TEST_PORT=${3000 + (Math.abs( new Random().nextInt() % (99 - 10) ) + 10)}"]){
//     try {
//       stage ('Checkout') {
//         checkout scm
//       }
      
//       stage ('Install Gems') {
//         rvmSh 'bundle install --path vendor/bundle --full-index --verbose'
//       }

//       stage ('Run Unit tests'){
//         sh 'printenv | sort'
//         rvmSh 'yarn install --check-files --ignore-engines'
//         rvmSh "export TMP_TEST_DB=${env.TMP_TEST_DB} && RAILS_ENV=test bundle exec rails db:create && RAILS_ENV=test bundle exec rails db:migrate && PORT=${env.TEST_PORT} && PORT=${env.TEST_PORT} CYPRESS_baseUrl=http://localhost:${env.TEST_PORT} yarn start-test 'start_test' 'http://localhost:${env.TEST_PORT}' cy:run"
//       }
      
//       if (env.BRANCH_NAME == 'master') {
//         stage ('Accept Staging Deployment') {
//           deploy = canDeploy()
//           if(deploy) {
//             stage 'Deploy to Staging'
//               echo 'Will deploy to Staging'
//           }
//         }
//       }

//       def tag = sh(returnStdout: true, script: "git tag --contains | head -1").trim()
//       if (tag) {
//         stage ('Accept Production Deployment') {
//           deploy = canDeploy()
//           if(deploy) {
//             stage 'Deploy to Production'
//               echo 'Will deploy to Production'
//           }
//         }
//       }
//     }
    
//     catch(err) {
//       notifyCulpritsOnEveryUnstableBuild()
//       currentBuild.result = 'FAILURE'
//       throw err
//     }

//     finally {
//       rvmSh "export TMP_TEST_DB=${env.TMP_TEST_DB} && RAILS_ENV=test bundle exec rails db:drop"
//     }
//   }
// }

// def rvmSh(String cmd) {
//     def sourceRvm = 'source /var/lib/jenkins/.rvm/scripts/rvm'
//     def useRuby = "/var/lib/jenkins/.rvm/bin/rvm use --install 2.5.3"
//     withEnv(["PATH=$PATH:/var/lib/jenkins/.rvm/bin"]) {
//       sh "${sourceRvm}; ${useRuby}; $cmd"
//     }
// }

// def notifyCulpritsOnEveryUnstableBuild() {
//   step([
//       $class : 'Mailer',
//       notifyEveryUnstableBuild: true,
//       recipients : emailextrecipients([[$class: 'CulpritsRecipientProvider'], [$class: 'RequesterRecipientProvider']])
//   ])
// }

// def canDeploy() {
//   def deploy = input(id: 'deploy', 
//     message: 'Let\'s deploy?', 
//     parameters: [ 
//       [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Deploy?', name: 'deploy']
//     ])
//   echo ('deploy:'+deploy)
//   deploy
// }
