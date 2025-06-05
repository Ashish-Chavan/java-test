import { View, ScrollView, Dimensions } from 'react-native';
import React from 'react';
import {Note,  Props } from './types';

import { getRequestAPI } from '@/src/services/api';

import GeneralETDetails from './GeneralETDetails';
import SFSETDetails from './SFSETDetails';

const EngineeringTaskDetails: React.FC<TaskDetailsProps> = ({
    task,
    colors,
    progressUpdate,
    canEdit,
    incident,
    handleClose,
}) => {
    const [showProgression, setShowProgression] = React.useState(true);
    const [notes, setNotes] = React.useState<Note[]>([]);
    const [showNotes, setshowNotes] = React.useState<boolean>(true);
    const windowHeight = Dimensions.get('window').height;
    const windowWidth = Dimensions.get('window').width;
    const scrollRef = React.useRef<ScrollView | null>(null);
    React.useEffect(() => {
        if (task && task.id) {
            fetchEngineeringTaskNotes();
        }
    

    const fetchEngineeringTaskNotes = async () => {
        const notesData: Note[] = await getRequestAPI(task.id);
        setNotes(notesData);
    };

    const scrollToBottom = () => {
        if (scrollRef.current) {
            scrollRef.current.scrollToEnd();
        }
    };

    const isSFSTask = Object.keys(task).includes('system');

    return (
        <View style={{ maxHeight: '80%' }}>
            <ScrollView
                style={{
                    flexWrap: 'nowrap',
                    padding: 16,
                    gap: 4,
                    margin: 0,
                    minHeight: windowHeight * 0.75,
                    width: 0.85 * windowWidth,
                    paddingBottom: 15,
                }}
                ref={scrollRef}
            >
                {isSFSTask ? (
                    <SFSETDetails
                        canEdit={canEdit}
                        colors={colors}
                        handleClose={handleClose}
                        incident={incident}
                        notes={notes}
                        progressUpdate={progressUpdate}
                        scrollToBottom={scrollToBottom}
                        setShowNotes={setshowNotes}
                        setShowProgression={setShowProgression}
                        showNotes={showNotes}
                        showProgression={showProgression}
                        task={task}
                    />
                ) : (
                    <GeneralETDetails
                        canEdit={canEdit}
                        colors={colors}
                        handleClose={handleClose}
                        incident={incident}
                        notes={notes}
                        progressUpdate={progressUpdate}
                        scrollToBottom={scrollToBottom}
                        setShowNotes={setshowNotes}
                        setShowProgression={setShowProgression}
                        showNotes={showNotes}
                        showProgression={showProgression}
                        task={task}
                    />
                )}
            </ScrollView>
        </View>
    );
};

export default EngineeringTaskDetails;
