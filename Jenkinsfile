pipeline {
  agent { label 'cloak' }
  
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
