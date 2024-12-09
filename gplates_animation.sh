#!/bin/bash
gmt gmtset FONT_ANNOT_PRIMARY 6.5p,Helvetica,black FONT_LABEL 9p,Helvetica,black MAP_LABEL_OFFSET 7p PS_PAGE_COLOR white
gmt gmtset MAP_FRAME_TYPE plain FORMAT_GEO_MAP dddF MAP_TICK_PEN 0.75p,black MAP_FRAME_PEN 0.75p,black MAP_TICK_LENGTH_PRIMARY=3.5p

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Animation of a spinning globe showcasing various things in GPlates
# created by nicky wright, last updated 2024-12-08

# Changes through time
## 0-30: with reconstructed etopo
## 31-60: pybacktrack paleobathymetry
## 60-100: traditional paleobathymetry
## 101-200: age grids
## 200-250: velocity arrows


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ----- input directory
gplates_recon_dir=/Users/nickywright/PostDoc/Projects/GPlatesExports/Muller++_2019

# ----- output directory
output_dir=gplates_animations
mkdir -p $output_dir

# ----- plot parameters
region=g

proj_lon=140  # Aus focus for the end frame

width=12
width_scalebar=`echo "scale=2; $width - 0.5" | bc `

coastline_col=grey80
cob_col=grey40

platethickness=0.75p
platecolour=black

plate_col_sub=black

# ------ 
echo "... creating cpts"
gmt makecpt -Cdeep -T-6500/0/100 -Z -I -M --COLOR_NAN=grey25 --COLOR_FOREGROUND=40/26/44 --COLOR_BACKGROUND=white > depth.cpt
gmt makecpt -Cinferno -T0/200/1 -I --COLOR_NAN=grey25 > age.cpt
gmt makecpt -Cviridis -T0/120/1 -D > vel.cpt


# topography.cpt is a manual merge of the two lines below...
# gmt makecpt -Cdeep -T-6500/0/50 -I  -M --COLOR_NAN=128/128/128 --COLOR_FOREGROUND=40/26/44 --COLOR_BACKGROUND=white > depth.cpt
# dem_poster.cpt is downloaded from cpt-city
# gmt makecpt -C/Users/nickywright/Data/ColourPalettes/dem_poster.cpt -T0/4000/50 --COLOR_NAN=128/128/128 > topo.cpt

# cpt=topography.cpt

max_frame=`echo "scale=2; (250 * 1) + 1" | bc `

# ----- start loop
age=0
max_age=250

while (( $age <= $max_age ))
do
	
	# ----- set up rotating globe
	rot_increment=1.43

	proj_lon_adj=`echo "scale=2; $proj_lon - (($age * $rot_increment))" | bc `
	frame_number=`echo "scale=2; $max_frame - ($age * 1)" | bc `

	projection=G${proj_lon_adj}/0/

	# ---- set filepaths
	# agegrids from Muller et al. 2019 - downloaded from EarthByte FTP
	agegrid=muller2019/Rasters/AgeGrids/Muller_etal_2019_Tectonics_v2.0_AgeGrid-${age}.nc

	# paleobathymetry created from wright et al. 2020
	paleobathy_W20=muller2019/Rasters/paleobathymetry/Grids-Muller_etal_2019_v2.0/paleobathymetry_${age}Ma.nc

	# paleobathymetry created using merge of pybacktrack and my synthetic stuff
	paleobathy=muller2019/Rasters/paleobathymetry-pybacktrack/merged/paleobathymetry_${age}Ma.nc

	# ---- Reconstructed exported features from GMT
	coastlines=${gplates_recon_dir}/Global_coastlines_low_res/reconstructed_${age}.00Ma.xy
	cobs=${gplates_recon_dir}/Global_EarthByte_GeeK07_COB_Terranes/reconstructed_${age}.00Ma.xy

	# ---- MOR's & SZ's
	subduction_left=${gplates_recon_dir}/topologies/topology_subduction_boundaries_sL_${age}.00Ma.xy
	subduction_right=${gplates_recon_dir}/topologies/topology_subduction_boundaries_sR_${age}.00Ma.xy
	ridges_transforms=${gplates_recon_dir}/topologies/topology_ridge_transform_boundaries_${age}.00Ma.xy
	plate_boundaries=${gplates_recon_dir}/topologies/topology_plate_boundaries_${age}.00Ma.xy
	
	# ---- velocity
	# velocity is exported from GPlates and is in the format:
	# lon | lat | velocity azimuth | velocity magnitude | plate ID
	# in cm/yr
	velocity=${gplates_recon_dir}/velocities/lat_lon_velocity_domain_18_36/velocity_${age}.00Ma.xy

	# reconstructed ETOPO data (from GPlates)
	etopo=${gplates_recon_dir}/ETOPO/raster_data_ETOPO1_Bed_g_6m_Rd_${age}.00Ma.nc

	# ---- output psfile
	psfile=${output_dir}/anim_f${frame_number}.ps
	
	# +++++++++++++++++++++++
	# --- plot
	# --- basemap--
	gmt psbasemap -R${region} -J${projection}${width} -Ba60f30/a30f15::NEWs -K -V -Xc -Yc --FONT_ANNOT_PRIMARY=6p,Helvetica,black > $psfile
	
	if [[ $age -ge 0 ]] && [[ $age -le 30 ]]; then
		cpt=topography.cpt
		# gmt grdgradient $paleobathy -Ggradient_${age}.nc -Ne0.2 -A45 -V
		gmt grdimage -R -J $paleobathy -C$cpt  -K -O -V -Q >> $psfile
		# gmt grdgradient $etopo -Ggradient_etopo_${age}.nc  -Ne0.2 -A45 -V
		gmt grdimage -R -J $etopo -C$cpt  -K -O -V -Q >> $psfile
		gmt psscale -R -J -C$cpt -I0.3 -DJBC+w${width_scalebar}c/0.4c+o0/0.6c+h+eb -Bxa1000f500+l"Elevation (m)" -N -V -O -K >> $psfile
	fi

	if [ $age -gt 30 ] && [ $age -le 60 ]; then
		cpt=depth.cpt
		gmt grdgradient $paleobathy -Ggradient_${age}.nc -Ne0.2 -A45 -V
		gmt grdimage -R -J $paleobathy -C$cpt  -Igradient_${age}.nc -K -O -V >> $psfile
		gmt psscale -R -J -C$cpt -I0.3 -DJBC+w${width_scalebar}c/0.4c+o0/0.6c+h+eb -Bxa1000f500+l"Depth (m)" -N -V -O -K >> $psfile	
		rm gradient_${age}.nc
	fi

	if [ $age -gt 60 ] && [ $age -le 100 ]; then
		cpt=depth.cpt
		gmt grdgradient $paleobathy_W20 -Ggradient_${age}.nc -Ne0.2 -A45 -V
		gmt grdimage -R -J $paleobathy_W20 -C$cpt  -Igradient_${age}.nc -K -O -V  >> $psfile
		gmt psscale -R -J -C$cpt -I0.3 -DJBC+w${width_scalebar}c/0.4c+o0/0.6c+h+eb -Bxa1000f500+l"Depth (m)" -N -V -O -K >> $psfile	
		rm gradient_${age}.nc
	fi

	if [ $age -gt 100 ] && [ $age -le 200 ]; then
		cpt=age.cpt
		gmt grdgradient $agegrid -Ggradient_${age}.nc -Ne0.1 -A45 -V
		# gmt grdimage -R -J $agegrid -C$agecpt -K -O -V -E500  >> $psfile
		gmt grdimage -R -J $agegrid -C$cpt  -Igradient_${age}.nc -K -O -V  >> $psfile
		gmt psscale -R -J -C$cpt -I0.3 -DJBC+w${width_scalebar}c/0.4c+o0/0.6c+h+ef -Bxa10f5+l"Age of oceanic crust (millions of years)" -N -V -O -K >> $psfile
		rm gradient_${age}.nc
	fi


	if [ $age -gt 30 ] ; then
		gmt psxy $cobs -R -J -W${cob_col}  -G${cob_col}  -K -O -N >> $psfile	
		gmt psxy $coastlines -R -J -W${coastline_col}  -G${coastline_col}  -K -O -N >> $psfile
	fi

	echo "... plotting plate boundaries"
	gmt psxy $ridges_transforms  -R -J  -W${platethickness},${platecolour}  -O -K -P >> $psfile
	gmt psxy $plate_boundaries -R -J -W${platethickness},${platecolour} -O -K -P >> $psfile
	gmt psxy -R -J $subduction_left -Sf0.3/0.09+l+t  -G${plate_col_sub} -W${platethickness},${plate_col_sub} -K -O >> $psfile
	gmt psxy -R -J $subduction_right -Sf0.3/0.09+r+t  -G${plate_col_sub} -W${platethickness},${plate_col_sub} -K -O >> $psfile

	# ----- plot velocities 
	if [ $age -gt 200 ] && [ $age -le 250 ]; then
		cpt=vel.cpt
		awk -F '>' '{ if ($1 != "") print $0}' $velocity | awk '{print $1, $2, $4*10, $3, $4/10}' > vel.dat
		gmt psxy -R -J vel.dat -SV0.02c/0.15c/0.1c  -K -O -V -C$cpt -W+c>> $psfile
		gmt psscale -R -J -C$cpt -I0.3 -DJBC+w${width_scalebar}c/0.4c+o0/0.6c+h+ef -Bxa10f5+l"Velocity (mm/yr)" -N -V -O -K >> $psfile
		rm vel.dat
	fi
	
	echo "... plotting basemap"
	gmt psbasemap -R${region} -J -Ba0 -K -O -V --FONT_ANNOT_PRIMARY=9p,Helvetica,black >> $psfile

	echo "... plotting age"
	echo "$age Ma" | gmt pstext -R0/10/0/10 -JX${width}/9.2 -F+cTL+f22p,Helvetica,black+jLB -D0/2 -N -O -V >> $psfile

	gmt psconvert $psfile -Tg -P -V -A


# ---- End line and clean up -----
age=$(($age + 1))
done

# --- create animation
# ffmpeg -r 10 -start_number 1 -i anim_f%d.png -pix_fmt yuv420p -vf "split=2[clr][bg];[bg]drawbox=c=white:t=fill[bg];[bg][clr]overlay,scale=trunc(iw/3.5)*2:trunc(ih/3.5)*2,pad=width=iw+50:height=ih+50:x=(ow-iw)/2:y=(oh-ih)/2:color=white" -y animation.mp4 < /dev/null