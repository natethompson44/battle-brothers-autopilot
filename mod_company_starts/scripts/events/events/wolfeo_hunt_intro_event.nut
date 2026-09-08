// Intro event for Wolfeo's Hunt.
this.wolfeo_hunt_intro_event <- this.inherit("scripts/events/event", {
	m = {},
	function create()
	{
		this.m.ID = "event.wolfeo_hunt_intro";
		this.m.IsSpecial = true;
		this.m.Screens.push({
			ID = "A",
			Text = "[img]gfx/ui/events/event_08.png[/img]Five men and six dogs, and one of the men is not really a man in the way the others are. The hunters have made their peace with that. Wolfeo pays, Wolfeo kills, and whatever is in the woods tonight will find out about both.\n\nNo banner, no line, no crowns to speak of. The board in the next village will have something with teeth on it. That is where the money is.",
			Image = "",
			Banner = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Find something that bleeds.",
					function getResult( _event )
					{
						return 0;
					}
				}
			],
			function start( _event )
			{
			}
		});
	}

	function onUpdateScore()
	{
		return;
	}

	function onPrepare()
	{
		this.m.Title = "Wolfeo's Hunt";
	}

	function onPrepareVariables( _vars )
	{
	}

	function onClear()
	{
		::Time.scheduleEvent(::TimeUnit.Real, 200, function ( _tag )
		{
			if (("State" in ::World) && ::World.State != null) ::World.State.setPause(false);
		}, null);
	}
});
