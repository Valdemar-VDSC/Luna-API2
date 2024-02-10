#tag BuildAutomation
			Begin BuildStepList Linux
				Begin BuildProjectStep Build
				End
				Begin CopyFilesBuildStep CopyFiles1
					AppliesTo = 0
					Architecture = 0
					Target = 0
					Destination = 0
					Subdirectory = db
					FolderItem = Li4vZXh0ZXJuYWxzL2RiL1Jlc2V0X0NvbnRhY3RzX1RhYmxlX0NyZWF0ZV9BbmRfTG9hZF9Qb3N0Z3Jlc3FsLnNxbA==
					FolderItem = Li4vZXh0ZXJuYWxzL2RiL1Jlc2V0X0NvbnRhY3RzX1RhYmxlX0NyZWF0ZV9BbmRfTG9hZF9TUUxpdGUuc3Fs
					FolderItem = Li4vZXh0ZXJuYWxzL2RiL1Jlc2V0X0NvbnRhY3RzX1RhYmxlX0NyZWF0ZV9BbmRfTG9hZC5zcWw=
					FolderItem = Li4vZXh0ZXJuYWxzL2RiL3N3YWdnZXIuanNvbg==
					FolderItem = Li4vZXh0ZXJuYWxzL2RiL3Rlc3RkYi5zcWxpdGU=
				End
				Begin CopyFilesBuildStep CopyFilesimg1
					AppliesTo = 0
					Architecture = 0
					Target = 0
					Destination = 0
					Subdirectory = img
					FolderItem = Li4vZXh0ZXJuYWxzL2ltYWdlcy9sdW5hX2xvZ29fMDMuanBn
					FolderItem = Li4vZXh0ZXJuYWxzL2ltYWdlcy9sdW5hX2xvZ29fMDMucG5n
				End
			End
			Begin BuildStepList Mac OS X
				Begin BuildProjectStep Build
				End
				Begin SignProjectStep Sign
				  DeveloperID=
				End
				Begin CopyFilesBuildStep CopyFiles12
					AppliesTo = 0
					Architecture = 0
					Target = 0
					Destination = 0
					Subdirectory = db
					FolderItem = Li4vZXh0ZXJuYWxzL2RiL1Jlc2V0X0NvbnRhY3RzX1RhYmxlX0NyZWF0ZV9BbmRfTG9hZF9Qb3N0Z3Jlc3FsLnNxbA==
					FolderItem = Li4vZXh0ZXJuYWxzL2RiL1Jlc2V0X0NvbnRhY3RzX1RhYmxlX0NyZWF0ZV9BbmRfTG9hZF9TUUxpdGUuc3Fs
					FolderItem = Li4vZXh0ZXJuYWxzL2RiL1Jlc2V0X0NvbnRhY3RzX1RhYmxlX0NyZWF0ZV9BbmRfTG9hZC5zcWw=
					FolderItem = Li4vZXh0ZXJuYWxzL2RiL3N3YWdnZXIuanNvbg==
					FolderItem = Li4vZXh0ZXJuYWxzL2RiL3Rlc3RkYi5zcWxpdGU=
				End
				Begin CopyFilesBuildStep CopyFilesimg
					AppliesTo = 0
					Architecture = 0
					Target = 0
					Destination = 0
					Subdirectory = img
					FolderItem = Li4vZXh0ZXJuYWxzL2ltYWdlcy9sdW5hX2xvZ29fMDMuanBn
					FolderItem = Li4vZXh0ZXJuYWxzL2ltYWdlcy9sdW5hX2xvZ29fMDMucG5n
				End
			End
			Begin BuildStepList Windows
				Begin BuildProjectStep Build
				End
				Begin CopyFilesBuildStep CopyFiles11
					AppliesTo = 0
					Architecture = 0
					Target = 0
					Destination = 0
					Subdirectory = db
					FolderItem = Li4vLi4vLi4vRG93bmxvYWRzL2x1bmEtbWFzdGVyL2V4dGVybmFscy9kYi90ZXN0ZGIuc3FsaXRl
				End
			End
			Begin BuildStepList Xojo Cloud
				Begin BuildProjectStep Build
				End
			End
#tag EndBuildAutomation
