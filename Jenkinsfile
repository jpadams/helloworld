pipeline {
  agent { label 'cloak' }
  
  environment {
    //https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#handling-credentials
    //DH_CREDS              = credentials('jenkins-dockerhub-creds')
    //AWS_ACCESS_KEY_ID     = credentials('jenkins-aws-secret-key-id')
    //AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws-secret-access-key')
    //https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#using-environment-variables
    //GREETING = "Hello there, Jenkins! Hello" 
  }
  stages {
    stage("run cloak") {
      steps {
        sh '''
	cd /cloak
	cloak -p cloak.yaml do << 'EOF'
	{
  		core {
    			git(remote: "https://github.com/dagger/dagger") {
      				dockerbuild(dockerfile: "Dockerfile") {
        				exec(input: { args: ["dagger", "version"] }) {
          					stdout
        }
      }
    }
  }
}
EOF
        '''
      }
    }
  }
}
