# Check if a command line argument is provided
if ($args.Count -ne 1) {
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) <remote-repo-url>, Please provide the remote repository URL as an argument."
    exit 1
}

# Get the remote repository URL from the command line
$remote_repo_url = $args[0]

# Initialize a new Git repository
git init

# Add all files to the staging area
git add .

# Commit the changes
git commit -m "initial commit"

# Rename the current branch to main
git branch -M main

# Add the remote repository
git remote add origin $remote_repo_url

# Push the changes to the main branch of the remote repository
git push -u origin main
