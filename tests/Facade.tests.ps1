. (Join-Path -Path ($MyInvocation.MyCommand.Path | Split-Path) -ChildPath "TestSetup.ps1")
EnsureTestEnvironment($MyInvocation.MyCommand.Path)

function SetupTempList {
	param([string] $path, [switch] $noTodoVariable)

	if(-not $noTodoVariable){
		Set-Variable -Name TODO_FILE -Value $path -Scope Global
	}

	$content = @"
This is the first line +project0 @context3
(A) This is the second line +project1 @context1
(D) This line has priority D @context2 @context4 +project0
(A) This is the last line
"@
	Set-Content -Path $path -Value $content
}

Mock LoadConfiguration { Write-Host "Mocked LoadConfiguration" } -ModuleName Facade
Mock Format-Priority { 
	param([object[]] $tasks)
	
	Write-Host "Mocked Format-Priority"

	$tasks | % { $_ } 

} -ModuleName Facade

Describe "Todo shell Facade" {

	Context "facade list" {
	
		BeforeEach {
			Set-Variable -Name TODO_FILE -Value ".\tests\data.txt" -Scope Global
		}
	
		AfterEach {
			Remove-Variable -Name TODO_FILE -Scope Global
		}

		It "should list tasks with the 'list' command aliases" -TestCases @( 
			@{ cmd = 'list' }
			@{ cmd = 'ls'; }
		) {
			param($cmd)
			((Todo $cmd) | Measure-Object).Count | Should Be 6 
			Assert-MockCalled -Scope It -ModuleName Facade -CommandName Format-Priority -Exactly 1
		}

	}

	Context "facade listall" {

		BeforeEach {
			Set-Variable -Name TODO_FILE -Value ".\tests\data.txt" -Scope Global
			Set-Variable -Name DONE_FILE -Value ".\tests\done.txt" -Scope Global
		}

		AfterEach {
			Remove-Variable -Name TODO_FILE -Scope Global
			Remove-Variable -Name DONE_FILE -Scope Global
		}

		It "should list tasks with the 'list' command aliases" -TestCases @( 
			@{ cmd = 'listall' }
			@{ cmd = 'lsa'; }
		) {
			param($cmd)
			((Todo $cmd) | Measure-Object).Count | Should Be 7 
			Assert-MockCalled -Scope It -ModuleName Facade -CommandName Format-Priority -Exactly 1
		}
	}

	Context "facade listfile" {

		It "should list tasks with the 'list' command aliases" -TestCases @( 
			@{ cmd = 'listfile' }
			@{ cmd = 'lf'; }
		) {
			param($cmd)
			((Todo $cmd ".\tests\data.txt") | Measure-Object).Count | Should Be 6 
			Assert-MockCalled -Scope It -ModuleName Facade -CommandName Format-Priority -Exactly 1
		}
	}

	Context "facade add" {

		BeforeEach {
			# Set up a throwaway txt data file
			SetupTempList -Path ".\tests\temp\facade_add_tests.txt"
		}

		# TODO make aftereach terse like you did in the edit-task tests
		AfterEach {
			Remove-Item $TODO_FILE
			Remove-Variable -Name TODO_FILE -Scope Global
		}

		It "should add a task with the 'add' command aliases" -TestCases @( 
			@{ cmd = 'add' }
			@{ cmd = 'a'; }
		) {
			param($cmd)

			$content = "A new task"

			Todo $cmd $content
			((Todo list) | Measure-Object).Count | Should Be 5 
			Get-Task $content | Should Be $content
		}

		# TODO Add some tests to set up Verbose for this to make sure the messages are showing up
	}

	Context "facade rm" {

		BeforeEach {
			# Set up a throwaway txt data file
			SetupTempList -Path ".\tests\temp\facade_rm_tests.txt"
		}

		AfterEach {
			Remove-Item $TODO_FILE
			Remove-Variable -Name TODO_FILE -Scope Global
		}

		It "should remove a task with the 'rm' command aliases" -TestCases @( 
			@{ cmd = 'rm' }
			@{ cmd = 'del'; }
		) {
			param($cmd)

			Todo $cmd 4
			((Todo list) | Measure-Object).Count | Should Be 3 
		}
	}

	Context "facade list projects" {

		BeforeEach {
			# Set up a throwaway txt data file
			SetupTempList -Path ".\tests\temp\facade_listproj_tests.txt"
		}

		AfterEach {
			Remove-Item $TODO_FILE
			Remove-Variable -Name TODO_FILE -Scope Global
		}

		It "should list projects with the 'listproj' command aliases" -TestCases @( 
			@{ cmd = 'listproj' }
			@{ cmd = 'lsprj'; }
		) {
			param($cmd)

			((Todo $cmd) | Measure-Object).Count | Should Be 2 
		}
	}

	Context "facade list contexts" {

		BeforeEach {
			# Set up a throwaway txt data file
			SetupTempList -Path ".\tests\temp\facade_listcon_tests.txt"
		}

		AfterEach {
			Remove-Item $TODO_FILE
			Remove-Variable -Name TODO_FILE -Scope Global
		}

		It "should list contexts with the 'listcon' command aliases" -TestCases @( 
			@{ cmd = 'listcon' }
			@{ cmd = 'lsc'; }
		) {
			param($cmd)

			((Todo $cmd) | Measure-Object).Count | Should Be 4 
		}
	}

	Context "facade list priority tasks" {

		BeforeEach {
			# Set up a throwaway txt data file
			SetupTempList -Path ".\tests\temp\facade_listpri_tests.txt"
		}

		AfterEach {
			Remove-Item $TODO_FILE
			Remove-Variable -Name TODO_FILE -Scope Global
		}

		It "should list tasks with priorities 'listpri' command aliases" -TestCases @( 
			@{ cmd = 'listpri' }
			@{ cmd = 'lsp'; }
		) {
			param($cmd)

			((Todo $cmd A) | Measure-Object).Count | Should Be 2 
			((Todo $cmd D) | Measure-Object).Count | Should Be 1 
			Assert-MockCalled -Scope It -ModuleName Facade -CommandName Format-Priority -Exactly 2
		}
	}
	
	Context "facade append to task" {

		BeforeEach {
			# Set up a throwaway txt data file
			SetupTempList -Path ".\tests\temp\facade_append_tests.txt"
		}

		AfterEach {
			Remove-Item $TODO_FILE
			Remove-Variable -Name TODO_FILE -Scope Global
		}

		It "should append to task with 'append' command aliases" -TestCases @( 
			@{ cmd = 'append' }
			@{ cmd = 'app'; }
		) {
			param($cmd)
			
			Todo $cmd 2 " some text" 
			Todo list "the second line" | Should Be "(A) This is the second line +project1 @context1 some text"
		}
	}

	# addm
	# replace
	# prepend
	
	# do
	# archive
	# pri
	# move
	# help
}