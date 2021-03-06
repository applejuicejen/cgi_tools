# BOUNCE LIGHT RENDER PASS SETUP - HOUDINI HSCRIPT VERSION 10.0

# TASK LIST

# DEFINE NAMES OF OBJECTS TO BE CREATED

    set gi_light = irradiance_light
    set s_net = gi_light_shaders
    set gi_shader = gi_light_shader
    set all = all_objects
    set obj_merge = scene_geometry
    set b_light = bounce_light

# END NAME DEFINITIONS

# OBJECT CLEANUP

    opcf /obj
    oprm -f $all $gi_light $b_light $s_net

# END OBJECT CLEANUP

# CREATE OBJECTS

# CREATE A GLOBAL ILLUMINATION LIGHT
    opcf /obj
    opadd light $gi_light
    opparm $gi_light shop_lightpath ( ../$s_net/$gi_shader )

    # NOTE - THIS SHOULD BE A LIGHT TEMPLATE OBJECT
    # NOTE - THIS OBJECT SHOULD HAVE THE GI SHADER ASSIGNED TO IT

# END CREATE GLOBAL ILLUMINATION LIGHT

# CREATE A SHOP NETWORK TO STORE A GI LIGHT SHADER
    # CREATE A GI LIGHT SHADER INSIDE IT
    opcf /obj
    opadd shopnet $s_net
        opcf ./$s_net
        opadd -n v_gilight $gi_shader
        opparm $gi_shader istyle ( full ) samples ( 32 ) doobjmask (on)  objmask ("* ^$all") background ( 0 0 0 )

# END CREATE SHOP NETWORK

# CREATE A GEO OBJECT THAT STORES A COPY OF THE SCENE GEOMETRY INSIDE IT
    opcf /obj
    opadd geo $all
    opparm $all lightmask ( $gi_light )
        #CREATE INSIDE IT AN OBJECT MERGE SOP
        opcf ./$all
                oprm file1
                opadd -n object_merge $obj_merge
                opparm $obj_merge xformpath (.)
        opcf ..
    # NOTE - THIS GEO SHOULD ONLY REACT TO THE GLOBAL ILLUMINATION LIGHT
    # NOTE - THIS GEO SHOULD CONTAIN AN OBJECT MERGE SOP TO CREATE THE COPY

# END CREATE SCENE COPY GEO

# CREATE A BOUNCE LIGHT
opcf /obj
opadd hlight $b_light
opparm $b_light l_t ( 10 10 10 ) l_lookatpath ( ../$all )
opparm $b_light light_type ( distant ) light_intensity ( 3 )  shadow_type ( raytrace )

    # NOTE - THIS SHOULD BE A REGULAR LIGHT
    # NOTE - THIS SHOULD BE POSITIONED SOMEWHERE USEFUL

# END CREATE OBJECTS

# EXAMINE EACH OBJECT IN TURN
    opcf /obj

    # CREATE A COUNT NUMBER
    set i = 1

        # FIND THE OBJECT NAME
        foreach name ( `execute("opls")` )
            #message OBJECT NAME is $name

        # FIND THE OBJECT TYPE
        set type = `execute("optype -t $name")`
        #message OBJECT NAME is $name OBJECT TYPE is $type

        # DETERMINE IF THE OBJECT IS ONE OF THE ORIGINAL GEOMETRY OBJECTS
        if ($type == geo && $name != $all)
            #message ORIGINAL GEOMETRY OBJECT FOUND

        # SET ORIGINAL GEOMETRY OBJECT AS A PHANTOM OBJECT
        # LIGHT-LINK THE ORIGINAL GEOMETRY TO THE BOUNCE LIGHT
        opparm $name lightmask ( $b_light ) vm_phantom ( on )

        # IMPORT ORIGINAL GEOMETRY OBJECT INTO OBECT MERGE SOP LOCATED IN ALL_OBJECTS
        opcf ./$all
                opparm $obj_merge numobj ($i) enable$i ( on )
                opparm $obj_merge objpath$i ( ../../$name )

                # INCREASE COUNTER
                set i = `$i + 1`

                # RETURN BACK TO OBJECT LEVEL
                opcf /obj

        endif

       # DETERMINE IF THE OBJECT IS AN ORIGINAL SCENE LIGHT
        if ($type == light || $type == hlight && $name != $gi_light && $name != $b_light)
       # DEACTIVATE LIGHT ENABLE ON ORIGINAL SCENE LIGHTS
                opparm $name light_enable ( off )
                
        endif

end

# END EXAMINE EACH OBJECT IN TURN