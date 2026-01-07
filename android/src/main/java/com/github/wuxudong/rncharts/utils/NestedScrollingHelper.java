package com.github.wuxudong.rncharts.utils;

import android.view.MotionEvent;
import android.view.ViewParent;

public class NestedScrollingHelper {
    private float mDownX;
    private float mDownY;
    
    public void saveDownCoordinates(MotionEvent ev) {
        if (ev.getAction() == MotionEvent.ACTION_DOWN) {
            mDownX = ev.getX();
            mDownY = ev.getY();
        }
    }

    public void handleNestedScroll(MotionEvent ev, ViewParent parent, boolean markerTouchActive) {
        if (parent == null) return;

        switch (ev.getAction()) {
            case MotionEvent.ACTION_DOWN:
                parent.requestDisallowInterceptTouchEvent(true);
                break;
            case MotionEvent.ACTION_MOVE:
                float x = ev.getX();
                float y = ev.getY();
                float xDelta = Math.abs(x - mDownX);
                float yDelta = Math.abs(y - mDownY);

                if (markerTouchActive) {
                    parent.requestDisallowInterceptTouchEvent(true);
                } else if (yDelta > xDelta) {
                    // Vertical scroll - let parent intercept
                    parent.requestDisallowInterceptTouchEvent(false);
                } else {
                    // Horizontal scroll - keep control
                    parent.requestDisallowInterceptTouchEvent(true);
                }
                break;
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                parent.requestDisallowInterceptTouchEvent(false);
                break;
        }
    }
}
