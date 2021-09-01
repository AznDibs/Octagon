-- SilentsReplacement
-- SharedConstants
-- August 04, 2021

return {
	Tags = {
		NoClipBlackListed = ("%s_NoClipBlackListed"),
		PrimaryPart = "PrimaryPart",
	},

	Vectors = {
		XZ = Vector3.new(1, 0, 1),
		Y = Vector3.new(0, 1, 0),
		Default = Vector3.new(),
	},

	FormattedOutputMessages = {
		Octagon = {
			Log = "[Octagon]",
			Debug = "[Octagon] [Debug]",
		},

		Util = {
			Log = "[Octagon] [Util]",
			Debug = "[Octagon] [Util] [Debug]",
		},
	},

	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}
