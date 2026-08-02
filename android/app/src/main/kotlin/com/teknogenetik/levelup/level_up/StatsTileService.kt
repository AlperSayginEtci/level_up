package com.teknogenetik.levelup.level_up

import android.content.Context
import android.content.SharedPreferences
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DeviceParametersBuilders.DeviceParameters
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.sp
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.LayoutElementBuilders.Column
import androidx.wear.protolayout.LayoutElementBuilders.Layout
import androidx.wear.protolayout.LayoutElementBuilders.Row
import androidx.wear.protolayout.LayoutElementBuilders.Spacer
import androidx.wear.protolayout.LayoutElementBuilders.Text
import androidx.wear.protolayout.ModifiersBuilders.Clickable
import androidx.wear.protolayout.ModifiersBuilders.Modifiers
import androidx.wear.protolayout.ResourceBuilders.Resources
import androidx.wear.protolayout.TimelineBuilders.Timeline
import androidx.wear.protolayout.TimelineBuilders.TimelineEntry
import androidx.wear.tiles.RequestBuilders.ResourcesRequest
import androidx.wear.tiles.RequestBuilders.TileRequest
import androidx.wear.tiles.TileBuilders.Tile
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

class StatsTileService : TileService() {
    private val RESOURCES_VERSION = "1"

    override fun onTileRequest(requestParams: TileRequest): ListenableFuture<Tile> {
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val level = prefs.getLong("flutter.stat_level", 1L)
        val rank = prefs.getString("flutter.stat_rank", "E-Rank") ?: "E-Rank"
        val str = prefs.getLong("flutter.stat_str", 1L)
        val agi = prefs.getLong("flutter.stat_agi", 1L)
        val intStat = prefs.getLong("flutter.stat_int", 1L)
        
        val tile = Tile.Builder()
            .setResourcesVersion(RESOURCES_VERSION)
            .setTileTimeline(
                Timeline.Builder()
                    .addTimelineEntry(
                        TimelineEntry.Builder()
                            .setLayout(
                                Layout.Builder()
                                    .setRoot(buildLayout(level, rank, str, agi, intStat, requestParams.deviceConfiguration))
                                    .build()
                            )
                            .build()
                    )
                    .build()
            )
            .build()
        
        return Futures.immediateFuture(tile)
    }

    override fun onTileResourcesRequest(requestParams: ResourcesRequest): ListenableFuture<Resources> {
        return Futures.immediateFuture(
            Resources.Builder()
                .setVersion(RESOURCES_VERSION)
                .build()
        )
    }

    private fun buildLayout(level: Long, rank: String, str: Long, agi: Long, intStat: Long, deviceParams: DeviceParameters): LayoutElementBuilders.LayoutElement {
        val clickable = Clickable.Builder()
            .setOnClick(ActionBuilders.LaunchAction.Builder().setAndroidActivity(
                ActionBuilders.AndroidActivity.Builder()
                    .setClassName(MainActivity::class.java.name)
                    .setPackageName(packageName)
                    .build()
            ).build())
            .build()

        return Column.Builder()
            .setModifiers(Modifiers.Builder().setClickable(clickable).build())
            .addContent(
                Text.Builder()
                    .setText("LVL $level")
                    .setFontStyle(LayoutElementBuilders.FontStyle.Builder()
                        .setColor(argb(0xFFFFFFFF.toInt()))
                        .setSize(sp(24f))
                        .setWeight(LayoutElementBuilders.FONT_WEIGHT_BOLD)
                        .build())
                    .build()
            )
            .addContent(
                Text.Builder()
                    .setText(rank)
                    .setFontStyle(LayoutElementBuilders.FontStyle.Builder()
                        .setColor(argb(0xFF448AFF.toInt())) // BlueAccent
                        .setSize(sp(14f))
                        .build())
                    .build()
            )
            .addContent(Spacer.Builder().setHeight(dp(12f)).build())
            .addContent(
                Row.Builder()
                    .addContent(buildStat("STR", str))
                    .addContent(Spacer.Builder().setWidth(dp(12f)).build())
                    .addContent(buildStat("AGI", agi))
                    .addContent(Spacer.Builder().setWidth(dp(12f)).build())
                    .addContent(buildStat("INT", intStat))
                    .build()
            )
            .build()
    }

    private fun buildStat(label: String, value: Long): LayoutElementBuilders.LayoutElement {
        return Column.Builder()
            .addContent(
                Text.Builder()
                    .setText(label)
                    .setFontStyle(LayoutElementBuilders.FontStyle.Builder()
                        .setColor(argb(0xFF9E9E9E.toInt()))
                        .setSize(sp(12f))
                        .build())
                    .build()
            )
            .addContent(
                Text.Builder()
                    .setText(value.toString())
                    .setFontStyle(LayoutElementBuilders.FontStyle.Builder()
                        .setColor(argb(0xFFFFFFFF.toInt()))
                        .setSize(sp(18f))
                        .setWeight(LayoutElementBuilders.FONT_WEIGHT_BOLD)
                        .build())
                    .build()
            )
            .build()
    }
}
