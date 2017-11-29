# SectorWatch

This script aids in implementing the sector roation strategy detailed in
this article:

http://stockcharts.com/school/doku.php?id=chart_school:trading_strategies:sector_rotation_roc

The strategy works as follows:

Buy Signal: When the S&P 500 is above its 10-month simple moving
average, buy the sectors with the biggest gains over a three-month
timeframe.

Sell Signal: Exit all positions when the S&P 500 moves below its
10-month simple moving average on a monthly closing basis.

Rebalance: Once per month, sell sectors that fall out of the top tier
(three) and buy the sectors that move into the top tier (three).
