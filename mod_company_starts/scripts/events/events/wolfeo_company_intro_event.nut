// Intro event for Wolfeo's Company. Every stock origin fires one right after spawning the party;
// closing it is what hands the world back to the player.
this.wolfeo_company_intro_event <- this.inherit("scripts/events/event", {
	m = {},
	function create()
	{
		this.m.ID = "event.wolfeo_company_intro";
		this.m.IsSpecial = true;
		this.m.Screens.push({
			ID = "A",
			Text = "[img]gfx/ui/events/event_35.png[/img]The dogs settle first. Nine of them, one for each of the company, lying in the road dust while their masters check straps and count arrows. Wolfeo does not check anything. He stands a little apart, as he always does, watching the treeline the way other men watch a fire.\n\nThe company knows the arrangement. They hold the line. He goes where the killing is and comes back. Nobody has yet seen him arrive at a fight, only leave one, and the men have stopped trying.\n\nThere is a village down the road, a board full of contracts, and three thousand crowns in the strongbox. Enough to replace a man. Not enough to waste one.",
			Image = "",
			Banner = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Let's earn our keep.",
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
		this.m.Title = "Wolfeo's Company";
	}

	function onPrepareVariables( _vars )
	{
	}

	function onClear()
	{
		// Belt and braces: make sure the clock is running once the intro is dismissed.
		::Time.scheduleEvent(::TimeUnit.Real, 200, function ( _tag )
		{
			if (("State" in ::World) && ::World.State != null) ::World.State.setPause(false);
		}, null);
	}
});
