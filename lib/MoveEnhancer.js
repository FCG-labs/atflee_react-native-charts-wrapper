import React, {Component} from 'react';
import { UIManager, findNodeHandle} from 'react-native';

function getCommand(extendedChart, commandName) {
  if (global?.nativeFabricUIManager) {
    return commandName;
  }

  return UIManager.getViewManagerConfig(extendedChart.getNativeComponentName()).Commands[commandName];
}


export default function MoveEnhancer(Chart) {
  return class MoveExtended extends Chart {
    // x, y, left/right
    moveViewTo(x, y, axisDependency) {
      UIManager.dispatchViewManagerCommand(
        findNodeHandle(this.getNativeComponentRef()),
        getCommand(this, 'moveViewTo'),
        [x, y, axisDependency]
      );
    }


    moveViewToX(x) {
      UIManager.dispatchViewManagerCommand(
        findNodeHandle(this.getNativeComponentRef()),
        getCommand(this, 'moveViewToX'),
        [x]
      );
    }

    moveViewToAnimated(x, y, axisDependency, duration) {
      UIManager.dispatchViewManagerCommand(
        findNodeHandle(this.getNativeComponentRef()),
        getCommand(this, 'moveViewToAnimated'),
        [x, y, axisDependency, duration]
      );
    }

    centerViewTo(x, y, axisDependency) {
      UIManager.dispatchViewManagerCommand(
        findNodeHandle(this.getNativeComponentRef()),
        getCommand(this, 'centerViewTo'),
        [x, y, axisDependency]
      );
    }

    centerViewToAnimated(x, y, axisDependency, duration) {
      UIManager.dispatchViewManagerCommand(
        findNodeHandle(this.getNativeComponentRef()),
        getCommand(this, 'centerViewToAnimated'),
        [x, y, axisDependency, duration]
      );
    }
  }
}