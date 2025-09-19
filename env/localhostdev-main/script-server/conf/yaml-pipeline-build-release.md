# Azure DevOps Pipelines Build & Release with YAML Templates 🚀

<hr /> 

<p><span style="color:#0CA656"><sup><strong>Evergreen</strong></sup> </span>
<sup>| Last Tended 🌳 Feb 28, 2021</sup></p>

<br>

In this piece we explore a technique for YAML pipeline modularization in Azure DevOps using YAML templates.  <br><br>
In a development team, or in your project, there are a few reasons as to why you may consider using templates for your pipelines.

Organizing your pipeline into multiple files in your version control system may allow for ease of substitution & reuse of each  `job / stage / step`.

From the perspective of practical collaboration - this also enables ease of code reviews on individual pipeline segments, as well as the separation of pipeline segment responsibility to different team members within your codebase (e.g. build, QA, release etc.). 

[You can read more about pipeline templates here](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops).

<br>

<hr /> 

### Getting Started

<br>

In this example, I will be building and releasing the **`PartsUnlimited`** template website from the ADO Demo Generator through the use of a pipeline built using multiple YAML files.  


Here are the requirements one should take note of in order to complete these steps:
<br><br>

  * **Azure DevOps Account** - visit [dev.azure.com](https://dev.azure.com) and sign in with your account.  
  
  * **PartsUnlimted Project** - visit [the Azure DevOps Demo Generator](https://azuredevopsdemogenerator.azurewebsites.net/) and sign in with your ADO account. Follow the prompts to generate a **`PartsUnlimited`** project into your ADO organization
  
  * **Azure Subscription** - to release our website via an Azure App Service you need a linked subscription from [portal.azure.com](https://portal.azure.com).  
  
  * **Azure Service Connection** - to use Azure resources you will also need [a valid service connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#create-a-service-connection).  
  
  * **YAML for ADO Pipelines** - In the example below we will be using pure YAML for our ADO build & release pipeline. Make sure you are at least familiar with this process. [Pipeline basics](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/key-pipelines-concepts?view=azure-devops) & [YAML schema](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema?view=azure-devops&tabs=schema%2Cparameter-schema) for reference.

<br>  
<hr /> 
  
<br><br>

### 1 | Creating the YAML files
<hr>

Before we create our Pipeline, we need to create the following YAML files in our project directory:
  * `azure-pipelines.yaml` - create in `root` directory 
  * `build.yaml` - create in `./pipeline-templates` directory 
  * `release.yaml` - create in `./pipeline-templates` directory 

<br>

### **The Main Pipeline File** 🛠
<br>

We will use the **`azure-pipelines.yaml`** file as our top-level YAML file. 

**This is the file we will directly link to our Pipeline.**
In this file, we specify the template files to use for the individual pipeline stages. _See line 11 & 12_.

We use the `build.yaml` template file for our build stage, and the `release.yaml` template file for our release stage :-)

Note that these files exist in a directory in our repository and that we could add additional stages using other custom templates as necessary (e.g. QA)

Also note, that in our release stage, we need to pass parameters from our [Pipeline variables](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch). In this case, I have specified these variables through the ADO pipeline UI. _See line 13 to 18_.
<br>
<br>

```yaml
# File: azure-pipelines.yaml
# This is the top-level YAML file that will orchestrate the pipeline

trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

stages:
- template: pipeline-templates/build.yaml
- template: pipeline-templates/release.yaml
  parameters:
      AdminPassword: $(AdminPassword)
      AdminTestPassword: $(AdminTestPassword)
      HostingPlan: $(HostingPlan)
      ServerName: $(ServerName)
      WebsiteName: $(WebsiteName) 

```
<sup>[azure-pipelines.yaml](github.com)</sup>

<hr style='border: 1px solid grey;' />  

<br>
<br>

### **The Build Stage** 📦
<br>

Here we examine the **`build.yaml`** template file.  

**This is the file that defines the build stage of our pipeline.**
In this file, we specify the various build parameters involved in packaging our project ahead of the release stage.

Notice the various tasks, associated here, including VSTest@2 task on _line 39_ which will run a series of test cases.

<br>

```yaml
# File: pipeline-templates/build.yaml
# This is a file elsewhere in the repository that represents 
# the build stage of our pipeline 

stages:
- stage: Build
  jobs:
  - job: Build
      
    pool:
      name: Hosted VS2017
      demands:
      - msbuild
      - visualstudio
      - vstest

    variables:
      solution: '**/*.sln'
      buildPlatform: 'Any CPU'
      buildConfiguration: 'Release'

    steps:
    - task: NuGetToolInstaller@1

    - task: NuGetCommand@2
      inputs:
        restoreSolution: '$(solution)'

    - task: VSBuild@1
      inputs:
        solution: '$(solution)'
        msbuildArgs: >-
          /p:DeployOnBuild=true /p:WebPublishMethod=Package 
          /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true 
          /p:PackageLocation="$(build.artifactStagingDirectory)"
        platform: '$(buildPlatform)'
        configuration: '$(buildConfiguration)'

    - task: VSTest@2
      inputs:
        platform: '$(buildPlatform)'
        configuration: '$(buildConfiguration)'

    - task: CopyFiles@2
      inputs:
        SourceFolder: '$(build.sourcesdirectory)/PartsUnlimited-aspnet45/env/'
        Contents: '**/*.json'
        TargetFolder: '$(Build.ArtifactStagingDirectory)'

    - task: PublishPipelineArtifact@1
      inputs:
        targetPath: '$(Build.ArtifactStagingDirectory)'
        artifact: 'drop'
        publishLocation: 'pipeline'  

```
<sup>[pipeline-templates/build.yaml](github.com)</sup>

<hr style='border: 1px solid grey;' /> 

<br>
<br>

### **The Release Stage** 🏷
<br>

Here we examine the **`release.yaml`** template file.  

**This is the file that defines the release stage of our pipeline.**
This is where we create our deployment to an Azure App Service.
Notice how we define the default parameters in case they are not explicitly passed from the top-level file.

Also note that on _line 28_ you will need to substitute the `azureResourceManagerConnection` value for an appropriate service connection, and add your `subscriptionId` to _line 29_ below. On _line 47_ replace the `azureSubscription` value with your service connection name.
<br>
<br>

```yaml
# File: pipeline-templates/release.yaml
# This is a file elsewhere in the repository that represents 
# the release stage of our pipeline 

parameters:
    AdminPassword: default
    AdminTestPassword: default
    HostingPlan: default
    ServerName: default
    WebsiteName: default
    
stages:
- stage: Deploy
  jobs:
  - job: Deploy
    pool:
      name: Hosted VS2017
    steps:
    - task: DownloadPipelineArtifact@2
      inputs:
        buildType: 'current'
        artifactName: 'drop'
        targetPath: '$(System.ArtifactsDirectory)'

    - task: AzureResourceManagerTemplateDeployment@3
      inputs:
        deploymentScope: 'Resource Group'
        azureResourceManagerConnection: '<SERVICE-CONNECTION>' # REPLACE with your service connection
        subscriptionId: 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' # REPLACE with your Subscription ID
        action: 'Create Or Update Resource Group'
        resourceGroupName: 'demo-rg'
        location: 'East US'
        templateLocation: 'Linked artifact'
        csmFile: '$(System.ArtifactsDirectory)/**/FullEnvironmentSetupMerged.json'
        csmParametersFile: '$(System.ArtifactsDirectory)/**/FullEnvironmentSetupMerged.param.json'
        overrideParameters: >- 
          -WebsiteName $(WebsiteName) 
          -PUL_ServerName $(ServerName) 
          -PUL_DBPassword $(AdminPassword) 
          -PUL_DBPasswordForTest $(AdminTestPassword) 
          -PUL_HostingPlanName $(HostingPlan)
        deploymentMode: 'Incremental'
    
    - task: AzureRmWebAppDeployment@4
      inputs:
        ConnectionType: 'AzureRM'
        azureSubscription: '<SERVICE-CONNECTION>' # REPLACE with your service connection
        appType: 'webApp'
        WebAppName: $(WebsiteName)
        packageForLinux: '$(Build.ArtifactStagingDirectory)/**/*.zip'

```
<sup>[pipeline-templates/release.yaml](github.com)</sup>

<hr style='border: 1px solid grey;' /> 
 

<br><br>

### 2 | Creating the Pipeline

<hr>


<br>
<br>

### **Select Main YAML file** 📃

<br>


In Azure DevOps, create a new pipeline with YAML and when you get to the **Configure** step, make sure to choose **Existing Azure Pipelines YAML file**.
Select **`azure-pipelines.yaml`** from the **Path** dropdown as shown below.
<br>

![image](https://user-images.githubusercontent.com/24496327/109435058-62aee480-79e6-11eb-9088-ea50bbeb21b5.png)

<br>

### **The Result** 🎯
<br>

After executing your pipeline, you should see the two stages **`Build`** & **`Deploy`**.

<br>
<br>

<img src="https://user-images.githubusercontent.com/24496327/109430406-4a7f9b00-79cf-11eb-88fd-de012fa69112.png" alt="build-release-success" width="750"/>
<br>
<br>
<sup>PartsUnlimted Pipeline Execution Result</sup>

<br>

*If you have correctly configured your **pipeline environment variables, service connection and Azure subscription** you should be able to deploy this example site successfully.*

From here you should be able to visit the URL associated with your website to see the deployed site.

<br>
<br>

## Conclusion
<hr>
<br>

Using templates can be helpful in defining comprehensive pipelines that would provide more functional value when modularized. Feel free to take this concept and apply it to your own development efforts. With YAML you can create a range of complex processes made simple through modularization.
<br>
<br>
<br>

##### Further Reading<br>

**[Pipeline Templates](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops)**<br>
**[Building GitHub Repositories](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/github?view=azure-devops&tabs=yaml)**<br>
**[Release Approvals and Gates Overview](https://docs.microsoft.com/en-us/azure/devops/pipelines/release/approvals/?view=azure-devops)**<br>
**[Gates in YAML Pipelines](https://stackoverflow.com/questions/61656077/implementing-gates-in-azure-yaml-pipelines)**<br>
